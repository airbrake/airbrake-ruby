module Airbrake
  # Query holds SQL query data that powers SQL query collection.
  #
  # @see Airbrake.notify_query
  # @api public
  # @since v3.2.0
  # rubocop:disable Metrics/ParameterLists
  class Query
    include HashKeyable
    include Ignorable
    include Stashable
    include Mergeable
    include Grouppable

    attr_accessor :method, :route, :query, :func, :file, :line, :start_time,
                  :end_time, :timing, :time

    def initialize(
      method:,
      route:,
      query:,
      func: nil,
      file: nil,
      line: nil,
      start_time: Time.now,
      end_time: start_time + 1,
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      @method = method
      @route = route
      @query = query
      @func = func
      @file = file
      @line = line
      @start_time = start_time
      @end_time = end_time
      @timing = timing
      @time = time
    end

    def destination
      'queries-stats'
    end

    def cargo
      'queries'
    end

    def to_h
      {
        'method' => method,
        'route' => route,
        'query' => query,
        'time' => @time_utc,
        'function' => func,
        'file' => file,
        'line' => line,
      }.delete_if { |_key, val| val.nil? }
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
