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
      super(method, route, query, func, file, line, start_time, end_time)
    end

    def name
      'queries'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'query' => query,
        'time' => TimeTruncate.utc_truncate_minutes(start_time),
        'function' => func,
        'file' => file,
        'line' => line
      }.delete_if { |_key, val| val.nil? }
    end
    # rubocop:enable Metrics/ParameterLists, Metrics/BlockLength
  end
end
