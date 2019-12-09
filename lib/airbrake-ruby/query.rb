module Airbrake
  # Query holds SQL query data that powers SQL query collection.
  #
  # @see Airbrake.notify_query
  # @api public
  # @since v3.2.0
  # rubocop:disable Metrics/ParameterLists, Metrics/BlockLength
  Query = Struct.new(
    :method, :route, :query, :func, :file, :line, :start_time, :end_time
  ) do
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable

    def initialize(
      method:,
      route:,
      query:,
      func: nil,
      file: nil,
      line: nil,
      start_time:,
      end_time: Time.now
    )
      @start_time_utc = TimeTruncate.utc_truncate_minutes(start_time)
      super(method, route, query, func, file, line, start_time, end_time)
    end

    def destination
      'queries-stats'
    end

    def cargo
      'queries'
    end

    def groups
      {}
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'query' => query,
        'time' => @start_time_utc,
        'function' => func,
        'file' => file,
        'line' => line
      }.delete_if { |_key, val| val.nil? }
    end
    # rubocop:enable Metrics/ParameterLists, Metrics/BlockLength
  end
end
