module Airbrake
  # Queue represents a queue (worker).
  #
  # @see Airbrake.notify_queue
  # @api public
  # @since v4.9.0
  # rubocop:disable Metrics/BlockLength, Metrics/ParameterLists
  Queue = Struct.new(
    :queue, :error_count, :groups, :start_time, :end_time, :timing, :time
  ) do
    include HashKeyable
    include Ignorable
    include Stashable

    def initialize(
      queue:,
      error_count:,
      groups: {},
      start_time: Time.now,
      end_time: start_time + 1,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      super(queue, error_count, groups, start_time, end_time, timing, time)
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
        'time' => @time_utc,
      }
    end

    def hash
      {
        'queue' => queue,
        'time' => @time_utc,
      }.hash
    end

    def merge(other)
      self.error_count += other.error_count
    end
  end
  # rubocop:enable Metrics/BlockLength, Metrics/ParameterLists
end
