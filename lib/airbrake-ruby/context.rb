module Airbrake
  # Represents a thread-safe Airbrake context object, which carries arbitrary
  # information added via {Airbrake.merge_context} calls.
  #
  # @example
  #   Airbrake::Context.current.merge!(foo: 'bar')
  #
  # @api private
  # @since v5.2.1
  class Context
    # Returns current, thread-local, context.
    # @return [self]
    def self.current
      Thread.current[:airbrake_context] ||= new
    end

    def initialize
      @mutex = Mutex.new
      @context = {}
    end

    # Merges the given context with the current one.
    #
    # @param [Hash{Object=>Object}] other
    # @return [void]
    def merge!(other)
      @mutex.synchronize do
        @context.merge!(other)
      end
    end

    # @return [Hash] duplicated Hash context
    def to_h
      @mutex.synchronize do
        @context.dup
      end
    end

    # @return [Hash] clears (resets) the current context
    def clear
      @mutex.synchronize do
        @context.clear
      end
    end

    # @return [Boolean] checks whether the context has any data
    def empty?
      @context.empty?
    end
  end
end
