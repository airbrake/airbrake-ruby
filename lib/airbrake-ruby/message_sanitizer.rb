module Airbrake
  # Utility for sanitizing exception messages for safe display in notices.
  module MessageSanitizer
    HIGHLIGHT_DIVIDER = "\n\n".freeze
    ENCODING_OPTIONS = { invalid: :replace, undef: :replace }.freeze

    def self.sanitize_exception_message(exception)
      return nil unless (msg = exception&.message)

      normalized = msg
        .encode(Encoding::UTF_8, **ENCODING_OPTIONS)
        .split(HIGHLIGHT_DIVIDER)
        .first

      if defined?(JSON) && (exception.is_a?(JSON::ParserError) rescue false)
        # Replace binary/control-laden parser fragments with a stable phrase.
        normalized = normalized.gsub(/unexpected character:.*?at/, 'unexpected token at')
      end

      normalized
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      # Best-effort fallback: return a short, stable string when encoding fails.
      'unreadable exception message'
    end
  end
end
