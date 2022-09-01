module Airbrake
  # A class that is capable of unwinding nested exceptions and representing them
  # as JSON-like hash.
  #
  # @api private
  # @since v1.0.4
  class NestedException
    # @return [Integer] the maximum number of nested exceptions that a notice
    #   can unwrap. Exceptions that have a longer cause chain will be ignored
    MAX_NESTED_EXCEPTIONS = 3

    # On Ruby 3.1+, the error highlighting gem can produce messages that can
    # span multiple lines. We don't display multiline error messages in the
    # title of the notice in the Airbrake dashboard. Therefore, we want to strip
    # out the higlighting part so that the errors look consistent. The full
    # message with the exception will be attached to the notice body.
    #
    # @return [String]
    RUBY_31_ERROR_HIGHLIGHTING_DIVIDER = "\n\n".freeze

    # @return [Hash] the options for +String#encode+
    ENCODING_OPTIONS = { invalid: :replace, undef: :replace }.freeze

    def initialize(exception)
      @exception = exception
    end

    def as_json
      unwind_exceptions.map do |exception|
        { type: exception.class.name,
          message: message(exception),
          backtrace: Backtrace.parse(exception) }
      end
    end

    private

    def unwind_exceptions
      exception_list = []
      exception = @exception

      while exception && exception_list.size < MAX_NESTED_EXCEPTIONS
        exception_list << exception
        exception = (exception.cause if exception.respond_to?(:cause))
      end

      exception_list
    end

    def message(exception)
      return unless (msg = exception.message)

      msg
        .encode(Encoding::UTF_8, **ENCODING_OPTIONS)
        .split(RUBY_31_ERROR_HIGHLIGHTING_DIVIDER)
        .first
    end
  end
end
