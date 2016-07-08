module Airbrake
  ##
  # Represents a chunk of information that is meant to be either sent to
  # Airbrake or ignored completely.
  class Notice
    # @return [Hash{Symbol=>String}] the information about the notifier library
    NOTIFIER = {
      name: 'airbrake-ruby'.freeze,
      version: Airbrake::AIRBRAKE_RUBY_VERSION,
      url: 'https://github.com/airbrake/airbrake-ruby'.freeze
    }.freeze

    ##
    # @return [Hash{Symbol=>String,Hash}] the information to be displayed in the
    #   Context tab in the dashboard
    CONTEXT = {
      os: RUBY_PLATFORM,
      language: "#{RUBY_ENGINE}/#{RUBY_VERSION}".freeze,
      notifier: NOTIFIER
    }.freeze

    ##
    # @return [Integer] the maxium size of the JSON payload in bytes
    MAX_NOTICE_SIZE = 64000

    ##
    # @return [Integer] the maximum size of hashes, arrays and strings in the
    #   notice.
    PAYLOAD_MAX_SIZE = 10000

    ##
    # @return [Array<StandardError>] the list of possible exceptions that might
    #   be raised when an object is converted to JSON
    JSON_EXCEPTIONS = [
      IOError,
      NotImplementedError,
      JSON::GeneratorError,
      Encoding::UndefinedConversionError
    ].freeze

    # @return [Array<Symbol>] the list of keys that can be be overwritten with
    #   {Airbrake::Notice#[]=}
    WRITABLE_KEYS = [
      :notifier,
      :context,
      :environment,
      :session,
      :params
    ].freeze

    ##
    # @return [String] the name of the host machine
    HOSTNAME = Socket.gethostname.freeze

    def initialize(config, exception, params = {})
      @config = config

      @private_payload = {
        notifier: NOTIFIER
      }.freeze

      @modifiable_payload = {
        errors: NestedException.new(exception, @config.logger).as_json,
        context: context(params),
        environment: {},
        session: {},
        params: params
      }

      @truncator = PayloadTruncator.new(PAYLOAD_MAX_SIZE, @config.logger)
    end

    ##
    # Converts the notice to JSON. Calls +to_json+ on each object inside
    # notice's payload. Truncates notices, JSON representation of which is
    # bigger than {MAX_NOTICE_SIZE}.
    #
    # @return [Hash{String=>String}, nil]
    def to_json
      loop do
        begin
          json = payload.to_json
        rescue *JSON_EXCEPTIONS => ex
          @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")
        else
          return json if json && json.bytesize <= MAX_NOTICE_SIZE
        end

        break if truncate_payload.zero?
      end
    end

    ##
    # Ignores a notice. Ignored notices never reach the Airbrake dashboard.
    #
    # @return [void]
    # @see #ignored?
    # @note Ignored noticed can't be unignored
    def ignore!
      @modifiable_payload = nil
    end

    ##
    # Checks whether the notice was ignored.
    #
    # @return [Boolean]
    # @see #ignore!
    def ignored?
      @modifiable_payload.nil?
    end

    ##
    # Reads a value from notice's modifiable payload.
    # @return [Object]
    #
    # @raise [Airbrake::Error] if the notice is ignored
    def [](key)
      raise_if_ignored
      @modifiable_payload[key]
    end

    ##
    # Writes a value to the modifiable payload hash. Restricts unrecognized
    # writes.
    # @example
    #   notice[:params][:my_param] = 'foobar'
    #
    # @return [void]
    # @raise [Airbrake::Error] if the notice is ignored
    # @raise [Airbrake::Error] if the +key+ is not recognized
    # @raise [Airbrake::Error] if the root value is not a Hash
    def []=(key, value)
      raise_if_ignored
      raise_if_unrecognized_key(key)
      raise_if_non_hash_value(value)

      @modifiable_payload[key] = value.to_hash
    end

    private

    def context(params)
      ctx = {
        version: @config.app_version,
        # We ensure that root_directory is always a String, so it can always be
        # converted to JSON in a predictable manner (when it's a Pathname and in
        # Rails environment, it converts to unexpected JSON).
        rootDirectory: @config.root_directory.to_s,
        environment: @config.environment,

        # Legacy Airbrake v4 behaviour.
        component: params.delete(:component),
        action: params.delete(:action),

        # Make sure we always send hostname.
        hostname: HOSTNAME
      }

      ctx.merge(CONTEXT).delete_if { |_key, val| val.nil? || val.empty? }
    end

    def raise_if_ignored
      return unless ignored?
      raise Airbrake::Error, 'cannot access ignored notice'
    end

    def raise_if_unrecognized_key(key)
      return if WRITABLE_KEYS.include?(key)
      raise Airbrake::Error,
            ":#{key} is not recognized among #{WRITABLE_KEYS}"
    end

    def raise_if_non_hash_value(value)
      return if value.respond_to?(:to_hash)
      raise Airbrake::Error, "Got #{value.class} value, wanted a Hash"
    end

    def payload
      @modifiable_payload.merge(@private_payload)
    end

    def truncate_payload
      @modifiable_payload[:errors].each do |error|
        @truncator.truncate_error(error)
      end

      Filters::FILTERABLE_KEYS.each do |key|
        @truncator.truncate_object(@modifiable_payload[key])
      end

      new_max_size = @truncator.reduce_max_size
      if new_max_size.zero?
        @config.logger.error(
          "#{LOG_LABEL} truncation failed. File an issue at " \
          "https://github.com/airbrake/airbrake-ruby " \
          "and attach the following payload: #{payload}"
        )
      end

      new_max_size
    end
  end
end
