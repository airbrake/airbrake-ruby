require_relative 'benchmark_helpers'

require 'securerandom'
require 'base64'

# Generates various strings for the benchmark.
module StringGenerator
  STRLEN = 32

  class << self
    # @return [String] a UTF-8 string with valid encoding and characters
    def utf8
      SecureRandom.hex(STRLEN).encode('utf-8')
    end

    # @return [String] a UTF-8 string with invalid encoding and characters.
    def invalid_utf8
      [invalid_string, invalid_string, invalid_string].join.encode('utf-8')
    end

    # @return [String] a UTF-8 string with valid encoding and charaters from
    #   unicode
    def unicode_utf8
      "ü ö ä Ä Ü Ö ß привет €25.00 한글".encode('utf-8')
    end

    # @return [String] an ASCII-8BIT string with valid encoding and random
    #   charaters
    def ascii_8bit_string
      SecureRandom.random_bytes(STRLEN).encode('ascii-8bit')
    end

    # @return [String] an ASCII-8BIT string with valid encoding and invalid
    #   charaters (which means it can't be converted to UTF-8 with plain
    #   +String#encode+
    def invalid_ascii_8bit_string
      Base64.decode64(Base64.encode64(invalid_string).encode('ascii-8bit'))
    end

    private

    def invalid_string
      "\xD3\xE6\xBC\x9D\xBA"
    end
  end
end

# Generates arrays of strings for the benchmark.
module BenchmarkCase
  # @return [Integer] number of strings to generate
  MAX = 100_000

  class << self
    def worst_ascii
      generate { StringGenerator.invalid_ascii_8bit_string }
    end

    def worst_utf8
      generate { StringGenerator.invalid_utf8 }
    end

    def mixed
      strings = []
      methods = StringGenerator.singleton_methods(false)

      # How many strings of a certain type should be generated.
      part = MAX / methods.size

      methods.each do |method|
        strings << Array.new(part) { StringGenerator.__send__(method) }
      end

      strings.flatten
    end

    def best
      generate { StringGenerator.utf8 }
    end

    private

    def generate(&block)
      Array.new(MAX, &block)
    end
  end
end

worst_case_utf8 = BenchmarkCase.worst_utf8
worst_case_ascii = BenchmarkCase.worst_ascii
mixed_case = BenchmarkCase.mixed
best_case = BenchmarkCase.best

# Make sure we never truncate strings,
# because this is irrelevant to this benchmark.
MAX_PAYLOAD_SIZE = 1_000_000
truncator = Airbrake::Truncator.new(MAX_PAYLOAD_SIZE)

Benchmark.bmbm do |bm|
  bm.report("(worst case utf8)  Truncator#truncate_string") do
    worst_case_utf8.each do |str|
      truncator.__send__(:truncate_string, str)
    end
  end

  bm.report("(worst case ascii) Truncator#truncate_string") do
    worst_case_ascii.each do |str|
      truncator.__send__(:truncate_string, str)
    end
  end

  bm.report("(mixed)            Truncator#truncate_string") do
    mixed_case.each do |str|
      truncator.__send__(:truncate_string, str)
    end
  end

  bm.report("(best case)        Truncator#truncate_string") do
    best_case.each do |str|
      truncator.__send__(:truncate_string, str)
    end
  end
end
