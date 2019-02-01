require 'tdigest'
require 'base64'

module Airbrake
  # QueryNotifier aggregates information about SQL queries and periodically sends
  # collected data to Airbrake.
  # @since v3.2.0
  class QueryNotifier
    # The key that represents a query event.
    QueryKey = Struct.new(:method, :route, :query, :time)

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
      @queries = {}
      @thread = nil
      @mutex = Mutex.new
    end

    # @macro see_public_api_method
    # @param [Hash] query_info
    # @param [Airbrake::Promise] promise
    # rubocop:disable Metrics/AbcSize
    def notify(query_info, promise = Airbrake::Promise.new)
      if @config.ignored_environment?
        return promise.reject("The '#{@config.environment}' environment is ignored")
      end

      unless @config.performance_stats
        return promise.reject("The Performance Stats feature is disabled")
      end

      query = create_query_key(
        query_info[:method],
        query_info[:route],
        query_info[:query],
        utc_truncate_minutes(query_info[:start_time])
      )

      @mutex.synchronize do
        @queries[query] ||= Airbrake::Stat.new
        @queries[query].increment(query_info[:start_time], query_info[:end_time])

        if @flush_period > 0
          schedule_flush(promise)
        else
          send(@queries, promise)
        end
      end

      promise
    end
    # rubocop:enable Metrics/AbcSize

    private

    def create_query_key(method, route, query, tm)
      # rubocop:disable Style/DateTime
      time = DateTime.new(
        tm.year, tm.month, tm.day, tm.hour, tm.min, 0, tm.zone || 0
      )
      # rubocop:enable Style/DateTime
      QueryKey.new(method, route, query, time.rfc3339)
    end

    def schedule_flush(promise)
      @thread ||= Thread.new do
        sleep(@flush_period)

        queries = nil
        @mutex.synchronize do
          queries = @queries
          @queries = {}
          @thread = nil
        end

        send(queries, promise)
      end

      # Setting a name is needed to test the timer.
      # Ruby <=2.2 doesn't support Thread#name, so we have this check.
      @thread.name = 'query-stat-thread' if @thread.respond_to?(:name)
    end

    def send(queries, promise)
      signature = "#{self.class.name}##{__method__}"
      raise "#{signature}: queries cannot be empty. Race?" if queries.none?

      @config.logger.debug("#{LOG_LABEL} #{signature}: #{queries}")

      @sender.send(
        { queries: queries.map { |k, v| k.to_h.merge(v.to_h) } },
        promise,
        URI.join(@config.host, "api/v5/projects/#{@config.project_id}/queries-stats")
      )
    end

    def utc_truncate_minutes(time)
      time_array = time.to_a
      time_array[0] = 0
      Time.utc(*time_array)
    end
  end
end
