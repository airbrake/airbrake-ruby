module Airbrake
  # QueryNotifier aggregates information about SQL queries and periodically sends
  # collected data to Airbrake.
  #
  # @api public
  # @since v3.2.0
  class PerformanceNotifier
    include Inspectable
    include Loggable

    def initialize
      @config = Airbrake::Config.instance
      @flush_period = Airbrake::Config.instance.performance_stats_flush_period
      @sender = SyncSender.new(:put)
      @payload = {}
      @schedule_flush = nil
      @mutex = Mutex.new
      @filter_chain = FilterChain.new
    end

    # @param [Hash] resource
    # @see Airbrake.notify_query
    # @see Airbrake.notify_request
    def notify(resource)
      promise = @config.check_configuration
      return promise if promise.rejected?

      promise = Airbrake::Promise.new
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

    # rubocop:disable Metrics/AbcSize
    def send(payload, promise)
      signature = "#{self.class.name}##{__method__}"
      raise "#{signature}: payload (#{payload}) cannot be empty. Race?" if payload.none?

      logger.debug("#{LOG_LABEL} #{signature}: #{payload}")

      payload.group_by { |k, _v| k.name }.each do |resource_name, data|
        data = { resource_name => data.map { |k, v| k.to_h.merge!(v.to_h) } }
        data['environment'] = @config.environment if @config.environment

        @sender.send(
          data,
          promise,
          URI.join(
            @config.host,
            "api/v5/projects/#{@config.project_id}/#{resource_name}-stats"
          )
        )
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
