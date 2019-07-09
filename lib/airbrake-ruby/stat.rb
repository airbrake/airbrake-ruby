require 'base64'

# rubocop:disable Metrics/BlockLength
module Airbrake
  # Stat is a data structure that allows accumulating performance data (route
  # performance, SQL query performance and such). It's powered by TDigests.
  #
  # Usually, one Stat corresponds to one resource (route or query,
  # etc.). Incrementing a stat means pushing new performance statistics.
  #
  # @example
  #   stat = Airbrake::Stat.new
  #   stat.increment(Time.now - 200)
  #   stat.to_h # Pack and serialize data so it can be transmitted.
  #
  # @since v3.2.0
  Stat = Struct.new(:count, :sum, :sumsq, :tdigest) do
    # @param [Integer] count How many times this stat was incremented
    # @param [Float] sum The sum of duration in milliseconds
    # @param [Float] sumsq The squared sum of duration in milliseconds
    # @param [TDigest::TDigest] tdigest Packed durations. By default,
    #   compression is 20
    def initialize(count: 0, sum: 0.0, sumsq: 0.0, tdigest: TDigest.new(0.05))
      super(count, sum, sumsq, tdigest)
    end

    # @return [Hash{String=>Object}] stats as a hash with compressed TDigest
    #   (serialized as base64)
    def to_h
      tdigest.compress!
      {
        'count' => count,
        'sum' => sum,
        'sumsq' => sumsq,
        'tdigest' => Base64.strict_encode64(tdigest.as_small_bytes)
      }
    end

    # Increments count and updates performance with the difference of +end_time+
    # and +start_time+.
    #
    # @param [Date] start_time
    # @param [Date] end_time
    # @return [void]
    def increment(start_time, end_time = nil)
      end_time ||= Time.new
      increment_ms((end_time - start_time) * 1000)
    end

    # Increments count and updates performance with given +ms+ value.
    #
    # @param [Float] ms
    # @return [void]
    def increment_ms(ms)
      self.count += 1

      self.sum += ms
      self.sumsq += ms * ms

      tdigest.push(ms)
    end

    # We define custom inspect so that we weed out uninformative TDigest, which
    # is also very slow to dump when we log Airbrake::Stat.
    #
    # @return [String]
    def inspect
      "#<struct Airbrake::Stat count=#{count}, sum=#{sum}, sumsq=#{sumsq}>"
    end
    alias_method :pretty_print, :inspect
  end
end
# rubocop:enable Metrics/BlockLength
