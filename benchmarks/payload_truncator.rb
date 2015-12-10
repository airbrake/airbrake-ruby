require_relative 'benchmark_helpers'

##
# Generates example errors that should be truncated.
class Payload
  def self.generate
    5000.times.map do |i|
      { type: "Error#{i}",
        message: 'X' * 300,
        backtrace: 300.times.map { 'Y' * 300 } }
    end
  end
end

# The maximum size of hashes, arrays and strings.
TRUNCATOR_MAX_SIZE = 500

# Reduce the logger overhead.
LOGGER = Logger.new('/dev/null')

truncate_error_payload = Payload.generate
truncate_object_payload = Payload.generate

truncator = Airbrake::PayloadTruncator.new(TRUNCATOR_MAX_SIZE, LOGGER)

Benchmark.bm do |bm|
  bm.report("PayloadTruncator#truncate_error ") do
    truncate_error_payload.each { |error| truncator.truncate_error(error) }
  end

  bm.report("PayloadTruncator#truncate_object") do
    truncate_object_payload.each { |error| truncator.truncate_object(error) }
  end
end
