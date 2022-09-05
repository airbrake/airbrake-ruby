module Airbrake
  # Responsible for sending notices to Airbrake asynchronously.
  #
  # @see SyncSender
  # @api private
  # @since v1.0.0
  class AsyncSender
    def initialize(method = :post, name = 'async-sender')
      @config = Airbrake::Config.instance
      @sync_sender = SyncSender.new(method)
      @name = name
    end

    # Asynchronously sends a notice to Airbrake.
    #
    # @param [Airbrake::Notice] payload Whatever needs to be sent
    # @return [Airbrake::Promise]
    def send(notice, promise, endpoint = @config.error_endpoint)
      unless thread_pool << [notice, promise, endpoint]
        return promise.reject(
          "AsyncSender has reached its capacity of #{@config.queue_size}",
        )
      end

      promise
    end

    # @return [void]
    def close
      @sync_sender.close
      thread_pool.close
    end

    # @return [Boolean]
    def closed?
      thread_pool.closed?
    end

    # @return [Boolean]
    def has_workers?
      thread_pool.has_workers?
    end

    private

    def thread_pool
      @thread_pool ||= ThreadPool.new(
        name: @name,
        worker_size: @config.workers,
        queue_size: @config.queue_size,
        block: proc { |args| @sync_sender.send(*args) },
      )
    end
  end
end
