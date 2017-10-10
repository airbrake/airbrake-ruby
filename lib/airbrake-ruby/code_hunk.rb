module Airbrake
  ##
  # Represents a small hunk of code consisting of a base line and a couple lines
  # around
  class CodeHunk
    ##
    # @return [Integer] the maximum length of a line
    MAX_LINE_LEN = 200

    ##
    # @return [Integer] how many lines should be read around the base line
    INTERVAL = 3

    def initialize(file, line, interval = INTERVAL)
      @file = file
      @line = line

      @start_line = [line - interval, 1].max
      @end_line = line + interval

      @code_hash = {}
    end

    ##
    # @return [Hash{Integer=>String}, nil] code hunk around the base line. When
    #   an error occurrs, returns a zero key Hash
    def to_h
      return @code_hash unless @code_hash.empty?
      return unless File.exist?(@file)

      begin
        fetch_code
      rescue StandardError => ex
        { 0 => ex }
      end

      @code_hash
    end

    private

    def fetch_code
      File.foreach(@file).with_index(1) do |line, i|
        next if i < @start_line
        break if i > @end_line

        @code_hash[i] = line[0...MAX_LINE_LEN].rstrip
      end
    end
  end
end
