module Airbrake
  # Benchmark benchmarks Ruby code.
  #
  # @since v4.3.0
  # @api private
  module Benchmark
    # Measures monotonic time for the given operation.
    def self.measure
      start = MonotonicTime.time_in_ms
      yield
      MonotonicTime.time_in_ms - start
    end
  end
end
