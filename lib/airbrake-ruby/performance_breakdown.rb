module Airbrake
  # PerformanceBreakdown holds data that shows how much time a request spent
  # doing certaing subtasks such as (DB querying, view rendering, etc).
  #
  # @see Airbrake.notify_breakdown
  # @api public
  # @since v4.2.0
  # rubocop:disable Metrics/BlockLength, Metrics/ParameterLists
  PerformanceBreakdown = Struct.new(
    :method, :route, :response_type, :groups, :start_time, :end_time, :timing,
    :time
  ) do
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable

    def initialize(
      method:,
      route:,
      response_type:,
      groups:,
      start_time: Time.now,
      end_time: start_time + 1,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      super(
        method, route, response_type, groups, start_time, end_time, timing, time
      )
    end

    def destination
      'routes-breakdowns'
    end

    def cargo
      'routes'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'responseType' => response_type,
        'time' => @time_utc,
      }.delete_if { |_key, val| val.nil? }
    end
  end
  # rubocop:enable Metrics/BlockLength, Metrics/ParameterLists
end
