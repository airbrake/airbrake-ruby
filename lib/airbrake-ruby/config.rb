module Airbrake
  ##
  # Represents the Airbrake config. A config contains all the options that you
  # can use to configure an Airbrake instance.
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
    # @return [Boolean] If true, we will never fallback to synchronous delivery
    #   of errors, as it happens by default when there are no async workers alive
    attr_accessor :always_async

    ##
    # @param [Hash{Symbol=>Object}] user_config the hash to be used to build the
    #   config
    def initialize(user_config = {})
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

      self.always_async = false

      merge(user_config)
    end

    ##
    # The full URL to the Airbrake Notice API. Based on the +:host+ option.
    # @return [URI] the endpoint address
    def endpoint
      @endpoint ||=
        begin
          self.host = ('https://' << host) if host !~ %r{\Ahttps?://}
          api = "/api/v3/projects/#{project_id}/notices?key=#{project_key}"
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

    private

    def set_option(option, value)
      __send__("#{option}=", value)
    rescue NoMethodError
      raise Airbrake::Error, "unknown option '#{option}'"
    end

    def set_endpoint(id, key, host)
      host = ('https://' << host) if host !~ %r{\Ahttps?://}
      @endpoint = URI.join(host, "/api/v3/projects/#{id}/notices?key=#{key}")
    end
  end
end
