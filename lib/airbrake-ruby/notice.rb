module Airbrake
  # Represents a chunk of information that is meant to be either sent to
  # Airbrake or ignored completely.
  #
  # @since v1.0.0
  class Notice
    # @return [Hash{Symbol=>String}] the information about the notifier library
    NOTIFIER = {
      name: 'airbrake-ruby'.freeze,
      version: Airbrake::AIRBRAKE_RUBY_VERSION,
      url: 'https://github.com/airbrake/airbrake-ruby'.freeze,
    }.freeze

    # @return [Hash{Symbol=>String,Hash}] the information to be displayed in the
    #   Context tab in the dashboard
    CONTEXT = {
      os: RUBY_PLATFORM,
      language: "#{RUBY_ENGINE}/#{RUBY_VERSION}".freeze,
      notifier: NOTIFIER,
    }.freeze

    # @return [Integer] the maxium size of the JSON payload in bytes
    MAX_NOTICE_SIZE = 64000

    # @return [Integer] the maximum size of hashes, arrays and strings in the
    #   notice.
    PAYLOAD_MAX_SIZE = 10000

    # @return [Array<StandardError>] the list of possible exceptions that might
    #   be raised when an object is converted to JSON
    JSON_EXCEPTIONS = [
      IOError,
      NotImplementedError,
      JSON::GeneratorError,
      Encoding::UndefinedConversionError,
    ].freeze

    # @return [Array<Symbol>] the list of keys that can be be overwritten with
    #   {Airbrake::Notice#[]=}
    WRITABLE_KEYS = %i[notifier context environment session params].freeze

    # @return [Array<Symbol>] parts of a Notice's payload that can be modified
    #   by the truncator
    TRUNCATABLE_KEYS = %i[errors environment session params].freeze

    # @return [String] the name of the host machine
    HOSTNAME = Socket.gethostname.freeze

    # @return [String]
    DEFAULT_SEVERITY = 'error'.freeze

    include Ignorable
    include Loggable
    include Stashable

    # @api private
    def initialize(exception, params = {})
      @config = Airbrake::Config.instance
      @payload = {
        errors: NestedException.new(exception).as_json,
        context: context,
        environment: {
          program_name: $PROGRAM_NAME,
        },
        session: {},
        params: params,
      }
      @truncator = Airbrake::Truncator.new(PAYLOAD_MAX_SIZE)

      stash[:exception] = exception
    end

    # Converts the notice to JSON. Calls +to_json+ on each object inside
    # notice's payload. Truncates notices, JSON representation of which is
    # bigger than {MAX_NOTICE_SIZE}.
    #
    # @return [Hash{String=>String}, nil]
    # @api private
    def to_json(*_args)
      loop do
        begin
          json = @payload.to_json
        rescue *JSON_EXCEPTIONS => ex
          logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")
        else
          return json if json && json.bytesize <= MAX_NOTICE_SIZE
        end

        break if truncate == 0
      end
    end

    # Reads a value from notice's payload.
    #
    # @return [Object]
    # @raise [Airbrake::Error] if the notice is ignored
    def [](key)
      raise_if_ignored
      @payload[key]
    end

    # Writes a value to the payload hash. Restricts unrecognized writes.
    #
    # @example
    #   notice[:params][:my_param] = 'foobar'
    #
    # @return [void]
    # @raise [Airbrake::Error] if the notice is ignored
    # @raise [Airbrake::Error] if the +key+ is not recognized
    # @raise [Airbrake::Error] if the root value is not a Hash
    def []=(key, value)
      raise_if_ignored

      unless WRITABLE_KEYS.include?(key)
        raise Airbrake::Error,
              ":#{key} is not recognized among #{WRITABLE_KEYS}"
      end

      unless value.respond_to?(:to_hash)
        raise Airbrake::Error, "Got #{value.class} value, wanted a Hash"
      end

      @payload[key] = value.to_hash
    end

    private

    def context
      {
        version: @config.app_version,
        versions: @config.versions,
        # We ensure that root_directory is always a String, so it can always be
        # converted to JSON in a predictable manner (when it's a Pathname and in
        # Rails environment, it converts to unexpected JSON).
        rootDirectory: @config.root_directory.to_s,
        environment: @config.environment,

        # Make sure we always send hostname.
        hostname: HOSTNAME,

        severity: DEFAULT_SEVERITY,
      }.merge(CONTEXT).delete_if { |_key, val| val.nil? || val.empty? }
    end

    def truncate
      TRUNCATABLE_KEYS.each do |key|
        @payload[key] = @truncator.truncate(@payload[key])
      end

      new_max_size = @truncator.reduce_max_size
      if new_max_size == 0
        logger.error(
          "#{LOG_LABEL} truncation failed. File an issue at " \
          "https://github.com/airbrake/airbrake-ruby " \
          "and attach the following payload: #{@payload}",
        )
      end

      new_max_size
    end
  end
end
