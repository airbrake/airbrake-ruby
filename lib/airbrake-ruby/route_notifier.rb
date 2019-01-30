require 'tdigest'
require 'base64'

module Airbrake
  # RouteNotifier aggregates information about requests and periodically sends
  # collected data to Airbrake.
  # @since v3.0.0
  # @api private
  class RouteNotifier
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
          'tdigest' => Base64.strict_encode64(tdigest.as_small_bytes)
        }
      end
    end

    # @param [Airbrake::Config] config
    def initialize(user_config)
      @config = (user_config.is_a?(Config) ? user_config : Config.new(user_config))

      raise Airbrake::Error, @config.validation_error_message unless @config.valid?

      @flush_period = @config.performance_stats_flush_period
      @sender = SyncSender.new(@config, :put)
      @routes = {}
      @thread = nil
      @mutex = Mutex.new
    end

    # @macro see_public_api_method
    # @param [Airbrake::Promise] promise
    def notify(request_info, promise = Airbrake::Promise.new)
      if @config.ignored_environment?
        return promise.reject("The '#{@config.environment}' environment is ignored")
      end

      unless @config.performance_stats
        return promise.reject("The Performance Stats feature is disabled")
      end

      route = create_route_key(
        request_info[:method],
        request_info[:route],
        request_info[:status_code],
        utc_truncate_minutes(request_info[:start_time])
      )

      @mutex.synchronize do
        @routes[route] ||= RouteStat.new
        increment_stats(request_info, @routes[route])

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

    def increment_stats(request_info, stat)
      stat.count += 1

      end_time = request_info[:end_time] || Time.new
      ms = (end_time - request_info[:start_time]) * 1000

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
      signature = "#{self.class.name}##{__method__}"
      raise "#{signature}: routes cannot be empty. Race?" if routes.none?

      @config.logger.debug(
        "#{LOG_LABEL} #{signature}: #{routes}"
      )

      @sender.send(
        { routes: routes.map { |k, v| k.to_h.merge(v.to_h) } },
        promise,
        URI.join(@config.host, "api/v5/projects/#{@config.project_id}/routes-stats")
      )
    end

    def utc_truncate_minutes(time)
      time_array = time.to_a
      time_array[0] = 0
      Time.utc(*time_array)
    end
  end
end
