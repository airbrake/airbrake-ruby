module Airbrake
  # PerformanceNotifier aggregates performance data and periodically sends it to
  # Airbrake.
  #
  # @api public
  # @since v3.2.0
  # rubocop:disable Metrics/ClassLength
  class PerformanceNotifier
    include Inspectable
    include Loggable

    def initialize
      @config = Airbrake::Config.instance
      @flush_period = Airbrake::Config.instance.performance_stats_flush_period
      @async_sender = AsyncSender.new(:put, self.class.name)
      @sync_sender = SyncSender.new(:put)
      @schedule_flush = nil
      @filter_chain = FilterChain.new

      @payload = {}.extend(MonitorMixin)
      @has_payload = @payload.new_cond
    end

    # @param [Hash] metric
    # @see Airbrake.notify_query
    # @see Airbrake.notify_request
    def notify(metric)
      @payload.synchronize do
        send_metric(metric, sync: false)
      end
    end

    # @param [Hash] metric
    # @since v4.10.0
    # @see Airbrake.notify_queue_sync
    def notify_sync(metric)
      send_metric(metric, sync: true).value
    end

    # @see Airbrake.add_performance_filter
    def add_filter(filter = nil, &block)
      @filter_chain.add_filter(block_given? ? block : filter)
    end

    # @see Airbrake.delete_performance_filter
    def delete_filter(filter_class)
      @filter_chain.delete_filter(filter_class)
    end

    def close
      @payload.synchronize do
        @schedule_flush.kill if @schedule_flush
        @sync_sender.close
        @async_sender.close
      end
    end

    private

    def schedule_flush
      @schedule_flush ||= Thread.new do
        loop do
          @payload.synchronize do
            @last_flush_time ||= MonotonicTime.time_in_s

            while (MonotonicTime.time_in_s - @last_flush_time) < @flush_period
              @has_payload.wait(@flush_period)
            end

            if @payload.none?
              @last_flush_time = nil
              next
            end

            send(@async_sender, @payload, Airbrake::Promise.new)
            @payload.clear
          end
        end
      end
    end

    def send_metric(metric, sync:)
      promise = check_configuration(metric)
      return promise if promise.rejected?

      @filter_chain.refine(metric)
      if metric.ignored?
        return Promise.new.reject("#{metric.class} was ignored by a filter")
      end

      update_payload(metric)
      if sync || @flush_period == 0
        send(@sync_sender, @payload, promise)
      else
        @has_payload.signal
        schedule_flush
      end
    end

    def update_payload(metric)
      if (total_stat = @payload[metric])
        @payload.key(total_stat).merge(metric)
      else
        @payload[metric] = { total: Airbrake::Stat.new }
      end

      @payload[metric][:total].increment_ms(metric.timing)

      metric.groups.each do |name, ms|
        @payload[metric][name] ||= Airbrake::Stat.new
        @payload[metric][name].increment_ms(ms)
      end
    end

    def check_configuration(metric)
      promise = @config.check_configuration
      return promise if promise.rejected?

      promise = @config.check_performance_options(metric)
      return promise if promise.rejected?

      if metric.timing && metric.timing == 0
        return Promise.new.reject(':timing cannot be zero')
      end

      Promise.new
    end

    def send(sender, payload, promise)
      raise "payload cannot be empty. Race?" if payload.none?

      with_grouped_payload(payload) do |metric_hash, destination|
        url = URI.join(
          @config.apm_host,
          "api/v5/projects/#{@config.project_id}/#{destination}",
        )

        logger.debug do
          "#{LOG_LABEL} #{self.class.name}##{__method__}: #{metric_hash}"
        end
        sender.send(metric_hash, promise, url)
      end

      promise
    end

    def with_grouped_payload(raw_payload)
      grouped_payload = raw_payload.group_by do |metric, _stats|
        [metric.cargo, metric.destination]
      end

      grouped_payload.each do |(cargo, destination), metrics|
        payload = {}
        payload[cargo] = serialize_metrics(metrics)
        payload['environment'] = @config.environment if @config.environment

        yield(payload, destination)
      end
    end

    def serialize_metrics(metrics)
      metrics.map do |metric, stats|
        metric_hash = metric.to_h.merge!(stats[:total].to_h)

        if metric.groups.any?
          group_stats = stats.reject { |name, _stat| name == :total }
          metric_hash['groups'] = group_stats.merge(group_stats) do |_name, stat|
            stat.to_h
          end
        end

        metric_hash
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
