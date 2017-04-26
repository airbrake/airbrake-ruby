module Airbrake
  ##
  # A class that is responsible for storing Airbrake Ruby thread context. A
  # thread context is a hash of arbitrary objects to be sent to Airbrake. The
  # implementation of the class relies on thread local variables.
  #
  # @since 2.1.0
  class ThreadContext
    ##
    # @return [String] the prefix of an Airbrake Ruby thread local variable
    CONTEXT_PREFIX = 'airbrake_ruby_context'.freeze

    def initialize(name)
      @context_key = "#{CONTEXT_PREFIX}_#{name}"
      clear
    end

    ##
    # Retrieves an object from the thread context by its +key+.
    #
    # @param [Symbol] key
    # @return [Object] an object stored in the thread context
    def [](key)
      to_h[key]
    end

    ##
    # Associates +value+ with +key+ and stores in the thread context.
    #
    # @param [Symbol] key
    # @param [Object] value
    # @return [void]
    def []=(key, value)
      context = to_h
      context[key] = value

      Thread.current.thread_variable_set(@context_key, context)
    end

    ##
    # Wipes out the contents of the thread context.
    #
    # @return [void]
    def clear
      Thread.current.thread_variable_set(@context_key, {})
    end

    ##
    # Converts the thread context to a Hash.
    #
    # @return [Hash{Symbol=>Object}]
    def to_h
      Thread.current.thread_variable_get(@context_key)
    end
  end
end
