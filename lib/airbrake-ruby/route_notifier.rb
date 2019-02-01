module Airbrake
  # RouteNotifier aggregates information about requests and periodically sends
  # collected data to Airbrake.
  # @since v3.0.0
  # @api private
  class RouteNotifier
    using TDigestBigEndianness

    # The key that represents a route.
    RouteKey = Struct.new(:method, :route, :statusCode, :time)

    # @param [Airbrake::Config] config
    def initialize(config)
      @config =
        if config.is_a?(Config)
          config
        else
          loc = caller_locations(1..1).first
          signature = "#{self.class.name}##{__method__}"
          warn(
            "#{loc.path}:#{loc.lineno}: warning: passing a Hash to #{signature} " \
            'is deprecated. Pass `Airbrake::Config` instead'
          )
          Config.new(config)
        end

      @flush_period = @config.performance_stats_flush_period
      @sender = SyncSender.new(@config, :put)
      @routes = {}
      @schedule_flush = nil
      @mutex = Mutex.new
    end

    # @macro see_public_api_method
    # @param [Airbrake::Promise] promise
    # rubocop:disable Metrics/AbcSize
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
        @routes[route] ||= Airbrake::Stat.new
        @routes[route].increment(request_info[:start_time], request_info[:end_time])

        if @flush_period > 0
          schedule_flush(promise)
        else
          send(@routes, promise)
        end
      end

      promise
    end
    # rubocop:enable Metrics/AbcSize

    private

    def create_route_key(method, route, status_code, tm)
      # rubocop:disable Style/DateTime
      time = DateTime.new(
        tm.year, tm.month, tm.day, tm.hour, tm.min, 0, tm.zone || 0
      )
      # rubocop:enable Style/DateTime
      RouteKey.new(method, route, status_code, time.rfc3339)
    end

    def schedule_flush(promise)
      @schedule_flush ||= Thread.new do
        sleep(@flush_period)

        routes = nil
        @mutex.synchronize do
          routes = @routes
          @routes = {}
          @schedule_flush = nil
        end

        send(routes, promise)
      end
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
