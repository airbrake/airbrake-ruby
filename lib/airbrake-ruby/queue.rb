module Airbrake
  # Queue represents a queue (worker).
  #
  # @see Airbrake.notify_queue
  # @api public
  # @since v4.9.0
  # rubocop:disable Metrics/BlockLength
  Queue = Struct.new(:queue, :error_count, :groups, :start_time, :end_time) do
    include HashKeyable
    include Ignorable
    include Stashable

    def initialize(
      queue:,
      error_count:,
      groups: {},
      start_time: Time.now,
      end_time: Time.now
    )
      @start_time_utc = TimeTruncate.utc_truncate_minutes(start_time)
      super(queue, error_count, groups, start_time, end_time)
    end

    def destination
      'queues-stats'
    end

    def cargo
      'queues'
    end

    def to_h
      {
        'queue' => queue,
        'errorCount' => error_count,
        'time' => @start_time_utc
      }
    end

    def hash
      {
        'queue' => queue,
        'time' => @start_time_utc
      }.hash
    end

    def merge(other)
      self.error_count += other.error_count
    end
  end
  # rubocop:enable Metrics/BlockLength
end
