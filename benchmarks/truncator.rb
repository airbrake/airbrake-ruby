require_relative 'benchmark_helpers'

##
# Generates example errors that should be truncated.
class Payload
  def self.generate
    Array.new(5000) do |i|
      { type: "Error#{i}",
        message: 'X' * 300,
        backtrace: Array.new(300) { 'Y' * 300 } }
    end
  end
end

# The maximum size of hashes, arrays and strings.
TRUNCATOR_MAX_SIZE = 500

# Reduce the logger overhead.
LOGGER = Logger.new('/dev/null')

truncate_payload = Payload.generate
truncator = Airbrake::Truncator.new(TRUNCATOR_MAX_SIZE)

Benchmark.bm do |bm|
  bm.report("Truncator#truncate") do
    truncate_payload.each { |error| truncator.truncate(error) }
  end
end
