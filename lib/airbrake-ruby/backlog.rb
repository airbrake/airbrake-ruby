module Airbrake
  # Backlog accepts notices and APM events and synchronously sends them in the
  # background at regular intervals. The backlog is a queue of data that failed
  # to be sent due to some error. In a nutshell, it's a retry mechanism.
  #
  # @api private
  # @since v6.2.0
  class Backlog
    include Loggable

    # @return [Integer] how many records to keep in the backlog
    BACKLOG_SIZE = 100

    # @return [Integer] flush period in seconds
    TWO_MINUTES = 60 * 2

    def initialize(sync_sender, flush_period = TWO_MINUTES)
      @sync_sender = sync_sender
      @flush_period = flush_period
      @queue = SizedQueue.new(BACKLOG_SIZE).extend(MonitorMixin)
      @has_backlog_data = @queue.new_cond
      @schedule_flush = nil

      @seen = Set.new
    end

    # Appends data to the backlog. Once appended, the flush schedule will
    # start. Chainable.
    #
    # @example
    #   backlog << [{ 'data' => 1 }, 'https://airbrake.io/api']
    #
    # @param [Array<#to_json, String>] data An array of two elements, where the
    #   first element is the data we are sending and the second element is the
    #   URL that we are sending to
    # @return [self]
    def <<(data)
      @queue.synchronize do
        return self if @seen.include?(data)

        @seen << data

        begin
          @queue.push(data, true)
        rescue ThreadError
          logger.error("#{LOG_LABEL} Airbrake::Backlog full")
          return self
        end

        @has_backlog_data.signal
        schedule_flush

        self
      end
    end

    # Closes all the resources that this sender has allocated.
    #
    # @return [void]
    # @since v6.2.0
    def close
      @queue.synchronize do
        if @schedule_flush
          @schedule_flush.kill
          logger.debug("#{LOG_LABEL} Airbrake::Backlog closed")
        end
      end
    end

    private

    def schedule_flush
      @schedule_flush ||= Thread.new do
        loop do
          @queue.synchronize do
            wait
            next if @queue.empty?

            flush
          end
        end
      end
    end

    def wait
      @has_backlog_data.wait(@flush_period) while time_elapsed < @flush_period
      @last_flush = nil
    end

    def time_elapsed
      MonotonicTime.time_in_s - last_flush
    end

    def last_flush
      @last_flush ||= MonotonicTime.time_in_s
    end

    def flush
      unless @queue.empty?
        logger.debug(
          "#{LOG_LABEL} Airbrake::Backlog flushing #{@queue.size} messages",
        )
      end

      failed = 0

      until @queue.empty?
        data, endpoint = @queue.pop
        promise = Airbrake::Promise.new
        @sync_sender.send(data, promise, endpoint)
        failed += 1 if promise.rejected?
      end

      if failed > 0
        logger.debug(
          "#{LOG_LABEL} Airbrake::Backlog #{failed} messages were not flushed",
        )
      end

      @seen.clear
    end
  end
end
