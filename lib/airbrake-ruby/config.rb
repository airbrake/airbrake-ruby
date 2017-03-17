module Airbrake
  ##
  # Represents the Airbrake config. A config contains all the options that you
  # can use to configure an Airbrake instance.
  #
  # @api private
  # @since v1.0.0
  class Config
    ##
    # @return [Integer] the project identificator. This value *must* be set.
    attr_accessor :project_id

    ##
    # @return [String] the project key. This value *must* be set.
    attr_accessor :project_key

    ##
    # @return [Hash] the proxy parameters such as (:host, :port, :user and
    #   :password)
    attr_accessor :proxy

    ##
    # @return [Logger] the default logger used for debug output
    attr_reader :logger

    ##
    # @return [String] the version of the user's application
    attr_accessor :app_version

    ##
    # @return [Integer] the max number of notices that can be queued up
    attr_accessor :queue_size

    ##
    # @return [Integer] the number of worker threads that process the notice
    #   queue
    attr_accessor :workers

    ##
    # @return [String] the host, which provides the API endpoint to which
    #   exceptions should be sent
    attr_accessor :host

    ##
    # @return [String, Pathname] the working directory of your project
    attr_accessor :root_directory

    ##
    # @return [String, Symbol] the environment the application is running in
    attr_accessor :environment

    ##
    # @return [Array<String, Symbol>] the array of environments that forbids
    #   sending exceptions when the application is running in them. Other
    #   possible environments not listed in the array will allow sending
    #   occurring exceptions.
    attr_accessor :ignore_environments

    ##
    # @return [Integer] The HTTP timeout in seconds.
    attr_accessor :timeout

    ##
    # @return [Array<String, Symbol, Regexp>] the keys, which should be
    #   filtered
    # @since 1.2.0
    attr_accessor :blacklist_keys

    ##
    # @return [Array<String, Symbol, Regexp>] the keys, which shouldn't be
    #   filtered
    # @since 1.2.0
    attr_accessor :whitelist_keys

    ##
    # @param [Hash{Symbol=>Object}] user_config the hash to be used to build the
    #   config
    def initialize(user_config = {})
      @validator = Config::Validator.new(self)

      self.proxy = {}
      self.queue_size = 100
      self.workers = 1

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

      merge(user_config)
    end

    ##
    # The full URL to the Airbrake Notice API. Based on the +:host+ option.
    # @return [URI] the endpoint address
    def endpoint
      @endpoint ||=
        begin
          self.host = ('https://' << host) if host !~ %r{\Ahttps?://}
          api = "api/v3/projects/#{project_id}/notices?key=#{project_key}"
          URI.join(host, api)
        end
    end

    ##
    # Sets the logger. Never allows to assign `nil` as the logger.
    # @return [Logger] the logger
    def logger=(logger)
      @logger = logger || @logger
    end

    ##
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

    ##
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

    ##
    # @return [Boolean] true if the config ignores current environment, false
    #   otherwise
    def ignored_environment?
      if ignore_environments.any? && environment.nil?
        logger.warn("#{LOG_LABEL} the 'environment' option is not set, " \
                    "'ignore_environments' has no effect")
      end

      ignore_environments.map(&:to_s).include?(environment.to_s)
    end

    private

    def set_option(option, value)
      __send__("#{option}=", value)
    rescue NoMethodError
      raise Airbrake::Error, "unknown option '#{option}'"
    end
  end
end
