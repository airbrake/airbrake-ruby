require 'tdigest'
require 'base64'

module Airbrake
  # RouteSender aggregates information about requests and periodically sends
  # collected data to Airbrake.
  # @since v3.0.0
  class RouteSender
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

    using TDigestBigEndianness

    # The key that represents a route.
    RouteKey = Struct.new(:method, :route, :statusCode, :time)

    # RouteStat holds data that describes a route's performance.
    RouteStat = Struct.new(:count, :sum, :sumsq, :tdigest) do
      # @param [Integer] count The number of requests
      # @param [Float] sum The sum of request duration in milliseconds
      # @param [Float] sumsq The squared sum of request duration in milliseconds
      # @param [TDigest::TDigest] tdigest By default, the compression is 20
      def initialize(
        count: 0, sum: 0.0, sumsq: 0.0, tdigest: TDigest::TDigest.new(0.05)
      )
        super(count, sum, sumsq, tdigest)
      end

      # @return [Hash{String=>Object}] the route stat as a hash with compressed
      #   and serialized as binary base64 tdigest
      def to_h
        tdigest.compress!
        {
          'count' => count,
          'sum' => sum,
          'sumsq' => sumsq,
          'tDigest' => Base64.strict_encode64(tdigest.as_small_bytes)
        }
      end
    end

    # @param [Airbrake::Config] config
    def initialize(config)
      @config = config
      @flush_period = config.route_stats_flush_period
      @sender = SyncSender.new(config, :put)
      @routes = {}
      @thread = nil
      @mutex = Mutex.new
    end

    # @macro see_public_api_method
    def inc_request(method, route, status_code, dur, tm)
      route = create_route_key(method, route, status_code, tm)

      promise = Airbrake::Promise.new

      @mutex.synchronize do
        @routes[route] ||= RouteStat.new
        increment_stats(@routes[route], dur)

        if @flush_period > 0
          schedule_flush(promise)
        else
          send(@routes, promise)
        end
      end

      promise
    end

    private

    def create_route_key(method, route, status_code, tm)
      # rubocop:disable Style/DateTime
      time = DateTime.new(
        tm.year, tm.month, tm.day, tm.hour, tm.min, 0, tm.zone || 0
      )
      # rubocop:enable Style/DateTime
      RouteKey.new(method, route, status_code, time.rfc3339)
    end

    def increment_stats(stat, dur)
      stat.count += 1

      ms = dur.to_f
      stat.sum += ms
      stat.sumsq += ms * ms

      stat.tdigest.push(ms)
    end

    def schedule_flush(promise)
      @thread ||= Thread.new do
        sleep(@flush_period)

        routes = nil
        @mutex.synchronize do
          routes = @routes
          @routes = {}
          @thread = nil
        end

        send(routes, promise)
      end

      # Setting a name is needed to test the timer.
      # Ruby <=2.2 doesn't support Thread#name, so we have this check.
      @thread.name = 'route-stat-thread' if @thread.respond_to?(:name)
    end

    def send(routes, promise)
      if routes.none?
        raise "#{self.class.name}##{__method__}: routes cannot be empty. Race?"
      end

      @config.logger.debug("#{LOG_LABEL} RouteStats#send: #{routes}")

      @sender.send(
        { routes: routes.map { |k, v| k.to_h.merge(v.to_h) } },
        promise,
        URI.join(@config.host, "api/v4/projects/#{@config.project_id}/routes-stats")
      )
    end
  end
end
