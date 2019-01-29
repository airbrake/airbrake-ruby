require 'tdigest'

module Airbrake
  # Monkey-patch https://github.com/castle/tdigest to pack with Big Endian
  # (instead of Little Endian) since our backend wants it.
  #
  # @see https://github.com/castle/tdigest/blob/master/lib/tdigest/tdigest.rb
  # @since v3.0.0
  # @api private
  module TDigestBigEndianness
    refine TDigest::TDigest do
      # rubocop:disable Metrics/AbcSize
      def as_small_bytes
        size = @centroids.size
        output = [self.class::SMALL_ENCODING, compression, size]
        x = 0
        # delta encoding allows saving 4-bytes floats
        mean_arr = @centroids.map do |_, c|
          val = c.mean - x
          x = c.mean
          val
        end
        output += mean_arr
        # Variable length encoding of numbers
        c_arr = @centroids.each_with_object([]) do |(_, c), arr|
          k = 0
          n = c.n
          while n < 0 || n > 0x7f
            b = 0x80 | (0x7f & n)
            arr << b
            n = n >> 7
            k += 1
            raise 'Unreasonable large number' if k > 6
          end
          arr << n
        end
        output += c_arr
        output.pack("NGNg#{size}C#{size}")
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
