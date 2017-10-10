module Airbrake
  ##
  # Represents a small hunk of code consisting of a base line and a couple lines
  # around it
  # @api private
  class CodeHunk
    ##
    # @return [Integer] the maximum length of a line
    MAX_LINE_LEN = 200

    ##
    # @return [Integer] how many lines should be read around the base line
    NLINES = 2

    def initialize(config)
      @config = config
    end

    ##
    # @param [String] file The file to read
    # @param [Integer] line The base line in the file
    # @return [Hash{Integer=>String}, nil] lines of code around the base line
    def get(file, line)
      return unless File.exist?(file)

      start_line = [line - NLINES, 1].max
      end_line = line + NLINES
      lines = {}

      begin
        File.foreach(file).with_index(1) do |l, i|
          next if i < start_line
          break if i > end_line

          lines[i] = l[0...MAX_LINE_LEN].rstrip
        end
      rescue StandardError => ex
        @config.logger.error(
          "#{self.class.name}##{__method__}: can't read code hunk for " \
          "#{file}:#{line}: #{ex}"
        )
      end

      return { 1 => '' } if lines.empty?
      lines
    end
  end
end
