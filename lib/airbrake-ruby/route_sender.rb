module Airbrake
  # RouteSender aggregates information about requests and periodically sends
  # collected data to Airbrake.
  # @since v2.13.0
  class RouteSender
    # The key that represents a route.
    RouteKey = Struct.new(:method, :route, :statusCode, :time)

    # RouteStat holds data that describes a route's performance.
    RouteStat = Struct.new(:count, :sum, :sumsq, :min, :max) do
      # @param [Integer] count The number of requests
      # @param [Float] sum The sum of request duration in milliseconds
      # @param [Float] sumsq The squared sum of request duration in milliseconds
      # @param [Float] min The minimal request duration
      # @param [Float] max The maximum request duration
      def initialize(count: 0, sum: 0.0, sumsq: 0.0, min: 0.0, max: 0.0)
        super(count, sum, sumsq, min, max)
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

      stat.min = ms if ms < stat.min || stat.min == 0
      stat.max = ms if ms > stat.max
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
