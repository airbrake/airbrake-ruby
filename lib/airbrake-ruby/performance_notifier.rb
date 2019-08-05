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

      promise = @config.check_performance_options(resource)
      return promise if promise.rejected?

      @filter_chain.refine(resource)
      return if resource.ignored?

      @mutex.synchronize do
        update_payload(resource)
        @flush_period > 0 ? schedule_flush(promise) : send(@payload, promise)
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

    def update_payload(resource)
      @payload[resource] ||= { total: Airbrake::Stat.new }
      @payload[resource][:total].increment(resource.start_time, resource.end_time)

      resource.groups.each do |name, ms|
        @payload[resource][name] ||= Airbrake::Stat.new
        @payload[resource][name].increment_ms(ms)
      end
    end

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

      logger.debug { "#{LOG_LABEL} #{signature}: #{payload}" }

      with_grouped_payload(payload) do |resource_hash, destination|
        url = URI.join(
          @config.host,
          "api/v5/projects/#{@config.project_id}/#{destination}"
        )
        @sender.send(resource_hash, promise, url)
      end

      promise
    end

    def with_grouped_payload(raw_payload)
      grouped_payload = raw_payload.group_by do |resource, _stats|
        [resource.cargo, resource.destination]
      end

      grouped_payload.each do |(cargo, destination), resources|
        payload = {}
        payload[cargo] = serialize_resources(resources)
        payload['environment'] = @config.environment if @config.environment

        yield(payload, destination)
      end
    end

    def serialize_resources(resources)
      resources.map do |resource, stats|
        resource_hash = resource.to_h.merge!(stats[:total].to_h)

        if resource.groups.any?
          group_stats = stats.reject { |name, _stat| name == :total }
          resource_hash['groups'] = group_stats.merge(group_stats) do |_name, stat|
            stat.to_h
          end
        end

        resource_hash
      end
    end
  end
end
