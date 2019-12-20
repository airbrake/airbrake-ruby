module Airbrake
  # Request holds request data that powers route stats.
  #
  # @see Airbrake.notify_request
  # @api public
  # @since v3.2.0
  # rubocop:disable Metrics/BlockLength, Metrics/ParameterLists
  Request = Struct.new(
    :method, :route, :status_code, :start_time, :end_time, :timing, :time
  ) do
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable
    include Grouppable

    def initialize(
      method:,
      route:,
      status_code:,
      start_time: Time.now,
      end_time: start_time + 1,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      super(method, route, status_code, start_time, end_time, timing, time)
    end

    def destination
      'routes-stats'
    end

    def cargo
      'routes'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'statusCode' => status_code,
        'time' => @time_utc,
      }.delete_if { |_key, val| val.nil? }
    end
  end
  # rubocop:enable Metrics/BlockLength, Metrics/ParameterLists
end
