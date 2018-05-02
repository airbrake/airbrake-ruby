module Airbrake
  # Represents the Airbrake config. A config contains all the options that you
  # can use to configure an Airbrake instance.
  #
  # @api private
  # @since v1.0.0
  class Config
    # @return [Integer] the project identificator. This value *must* be set.
    # @api public
    attr_accessor :project_id

    # @return [String] the project key. This value *must* be set.
    # @api public
    attr_accessor :project_key

    # @return [Hash] the proxy parameters such as (:host, :port, :user and
    #   :password)
    # @api public
    attr_accessor :proxy

    # @return [Logger] the default logger used for debug output
    # @api public
    attr_reader :logger

    # @return [String] the version of the user's application
    # @api public
    attr_accessor :app_version

    # @return [Hash{String=>String}] arbitrary versions that your app wants to
    #   track
    # @api public
    # @since v2.10.0
    attr_accessor :versions

    # @return [Integer] the max number of notices that can be queued up
    # @api public
    attr_accessor :queue_size

    # @return [Integer] the number of worker threads that process the notice
    #   queue
    # @api public
    attr_accessor :workers

    # @return [String] the host, which provides the API endpoint to which
    #   exceptions should be sent
    # @api public
    attr_accessor :host

    # @return [String, Pathname] the working directory of your project
    # @api public
    attr_accessor :root_directory

    # @return [String, Symbol] the environment the application is running in
    # @api public
    attr_accessor :environment

    # @return [Array<String,Symbol,Regexp>] the array of environments that
    #   forbids sending exceptions when the application is running in them.
    #   Other possible environments not listed in the array will allow sending
    #   occurring exceptions.
    # @api public
    attr_accessor :ignore_environments

    # @return [Integer] The HTTP timeout in seconds.
    # @api public
    attr_accessor :timeout

    # @return [Array<String, Symbol, Regexp>] the keys, which should be
    #   filtered
    # @api public
    # @since 1.2.0
    attr_accessor :blacklist_keys

    # @return [Array<String, Symbol, Regexp>] the keys, which shouldn't be
    #   filtered
    # @api public
    # @since 1.2.0
    attr_accessor :whitelist_keys

    # @return [Boolean] true if the library should attach code hunks to each
    #   frame in a backtrace, false otherwise
    # @api public
    # @since v2.5.0
    attr_accessor :code_hunks

    # @param [Hash{Symbol=>Object}] user_config the hash to be used to build the
    #   config
    def initialize(user_config = {})
      @validator = Config::Validator.new(self)

      self.proxy = {}
      self.queue_size = 100
      self.workers = 1
      self.code_hunks = true

      self.logger = Logger.new(STDOUT)
      logger.level = Logger::WARN

      self.project_id = user_config[:project_id]
      self.project_key = user_config[:project_key]
      self.host = 'https://airbrake.io'

      self.ignore_environments = []

      self.timeout = user_config[:timeout]

      self.blacklist_keys = []
      self.whitelist_keys = []

      self.root_directory = File.realpath(
        (defined?(Bundler) && Bundler.root) ||
        Dir.pwd
      )

      self.versions = {}

      merge(user_config)
    end

    # The full URL to the Airbrake Notice API. Based on the +:host+ option.
    # @return [URI] the endpoint address
    def endpoint
      @endpoint ||=
        begin
          self.host = ('https://' << host) if host !~ %r{\Ahttps?://}
          api = "api/v3/projects/#{project_id}/notices"
          URI.join(host, api)
        end
    end

    # Sets the logger. Never allows to assign `nil` as the logger.
    # @return [Logger] the logger
    def logger=(logger)
      @logger = logger || @logger
    end

    # Merges the given +config_hash+ with itself.
    #
    # @example
    #   config.merge(host: 'localhost:8080')
    #
    # @return [self] the merged config
    def merge(config_hash)
      config_hash.each_pair { |option, value| set_option(option, value) }
      self
    end

    # @return [Boolean] true if the config meets the requirements, false
    #   otherwise
    def valid?
      return true if ignored_environment?

      return false unless @validator.valid_project_id?
      return false unless @validator.valid_project_key?
      return false unless @validator.valid_environment?

      true
    end

    def validation_error_message
      @validator.error_message
    end

    # @return [Boolean] true if the config ignores current environment, false
    #   otherwise
    def ignored_environment?
      if ignore_environments.any? && environment.nil?
        logger.warn("#{LOG_LABEL} the 'environment' option is not set, " \
                    "'ignore_environments' has no effect")
      end

      env = environment.to_s
      ignore_environments.any? do |pattern|
        if pattern.is_a?(Regexp)
          env.match(pattern)
        else
          env == pattern.to_s
        end
      end
    end

    private

    def set_option(option, value)
      __send__("#{option}=", value)
    rescue NoMethodError
      raise Airbrake::Error, "unknown option '#{option}'"
    end
  end
end
