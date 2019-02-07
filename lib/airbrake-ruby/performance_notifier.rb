module Airbrake
  # QueryNotifier aggregates information about SQL queries and periodically sends
  # collected data to Airbrake.
  #
  # @api public
  # @since v3.2.0
  class PerformanceNotifier
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
      @payload = {}
      @schedule_flush = nil
      @mutex = Mutex.new
      @filter_chain = FilterChain.new
    end

    # @param [Hash] resource
    # @param [Airbrake::Promise] promise
    # @see Airbrake.notify_query
    # @see Airbrake.notify_request
    def notify(resource, promise = Airbrake::Promise.new)
      if @config.ignored_environment?
        return promise.reject("The '#{@config.environment}' environment is ignored")
      end

      unless @config.performance_stats
        return promise.reject("The Performance Stats feature is disabled")
      end

      @filter_chain.refine(resource)
      return if resource.ignored?

      @mutex.synchronize do
        @payload[resource] ||= Airbrake::Stat.new
        @payload[resource].increment(resource.start_time, resource.end_time)

        if @flush_period > 0
          schedule_flush(promise)
        else
          send(@payload, promise)
        end
      end

      promise
    end

    # @see Airbrake.add_performance_filter
    def add_filter(filter = nil, &block)
      @filter_chain.add_filter(block_given? ? block : filter)
    end

    # @see Airbrake.delete_performance_filter
    def delete_filter(filter_class)
      @filter_chain.delete_filter(filter_class)
    end

    private

    def schedule_flush(promise)
      @schedule_flush ||= Thread.new do
        sleep(@flush_period)

        payload = nil
        @mutex.synchronize do
          payload = @payload
          @payload = {}
          @schedule_flush = nil
        end

        send(payload, promise)
      end
    end

    def send(payload, promise)
      signature = "#{self.class.name}##{__method__}"
      raise "#{signature}: payload (#{payload}) cannot be empty. Race?" if payload.none?

      @config.logger.debug("#{LOG_LABEL} #{signature}: #{payload}")

      payload.group_by { |k, _v| k.name }.each do |resource_name, data|
        @sender.send(
          { resource_name => data.map { |k, v| k.to_h.merge!(v.to_h) } },
          promise,
          URI.join(
            @config.host,
            "api/v5/projects/#{@config.project_id}/#{resource_name}-stats"
          )
        )
      end
    end
  end

  # Request holds request data that powers route stats.
  #
  # @see Airbrake.notify_request
  # @api public
  # @since v3.2.0
  Request = Struct.new(:method, :route, :status_code, :start_time, :end_time) do
    include HashKeyable
    include Ignorable

    def initialize(method:, route:, status_code:, start_time:, end_time: Time.now)
      @ignored = false
      super(method, route, status_code, start_time, end_time)
    end

    def name
      'routes'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'statusCode' => status_code,
        'time' => TimeTruncate.utc_truncate_minutes(start_time)
      }
    end
  end

  # Query holds SQL query data that powers SQL query collection.
  #
  # @see Airbrake.notify_query
  # @api public
  # @since v3.2.0
  Query = Struct.new(:method, :route, :query, :start_time, :end_time) do
    include HashKeyable
    include Ignorable

    def initialize(method:, route:, query:, start_time:, end_time: Time.now)
      super(method, route, query, start_time, end_time)
    end

    def name
      'queries'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'query' => query,
        'time' => TimeTruncate.utc_truncate_minutes(start_time)
      }
    end
  end
end
