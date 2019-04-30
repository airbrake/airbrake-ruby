module Airbrake
  # PerformanceBreakdown holds data that shows how much time a request spent
  # doing certaing subtasks such as (DB querying, view rendering, etc).
  #
  # @see Airbrake.notify_breakdown
  # @api public
  # @since v4.2.0
  # rubocop:disable Metrics/BlockLength, Metrics/ParameterLists
  PerformanceBreakdown = Struct.new(
    :method, :route, :response_type, :groups, :start_time, :end_time
  ) do
    include HashKeyable
    include Ignorable

    def initialize(
      method:,
      route:,
      response_type:,
      groups:,
      start_time:,
      end_time: Time.now
    )
      super(method, route, response_type, groups, start_time, end_time)
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
        'time' => TimeTruncate.utc_truncate_minutes(start_time)
      }.delete_if { |_key, val| val.nil? }
    end
  end
  # rubocop:enable Metrics/BlockLength, Metrics/ParameterLists
end
