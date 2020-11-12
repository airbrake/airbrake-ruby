module Airbrake
  # RemoteSettings polls the remote config of the passed project at fixed
  # intervals. The fetched config is yielded as a callback parameter so that the
  # invoker can define read config values.
  #
  # @example Disable/enable error notifications based on the remote value
  #   RemoteSettings.poll do |data|
  #     config.error_notifications = data.error_notifications?
  #   end
  #
  # @since 5.0.0
  # @api private
  class RemoteSettings
    include Airbrake::Loggable

    # @return [Hash{Symbol=>String}] metadata to be attached to every GET
    #   request
    QUERY_PARAMS = URI.encode_www_form(
      notifier_name: Airbrake::NOTIFIER_INFO[:name],
      notifier_version: Airbrake::NOTIFIER_INFO[:version],
      os: RUBY_PLATFORM,
      language: "#{RUBY_ENGINE}/#{RUBY_VERSION}".freeze,
    ).freeze

    # Polls remote config of the given project.
    #
    # @param [Integer] project_id
    # @param [String] host
    # @yield [data]
    # @yieldparam data [Airbrake::RemoteSettings::SettingsData]
    # @return [Airbrake::RemoteSettings]
    def self.poll(project_id, host, &block)
      new(project_id, host, &block).poll
    end

    # @param [Integer] project_id
    # @yield [data]
    # @yieldparam data [Airbrake::RemoteSettings::SettingsData]
    def initialize(project_id, host, &block)
      @data = SettingsData.new(project_id, {})
      @host = host
      @block = block
      @poll = nil
    end

    # Polls remote config of the given project in background.
    #
    # @return [self]
    def poll
      @poll ||= Thread.new do
        @block.call(@data)

        loop do
          @block.call(@data.merge!(fetch_config))
          sleep(@data.interval)
        end
      end

      self
    end

    # Stops the background poller thread.
    #
    # @return [void]
    def stop_polling
      @poll.kill if @poll
    end

    private

    def fetch_config
      response = nil
      begin
        response = Net::HTTP.get(build_config_uri)
      rescue StandardError => ex
        logger.error(ex)
        return {}
      end

      # AWS S3 API returns XML when request is not valid. In this case we just
      # print the returned body and exit the method.
      if response.start_with?('<?xml ') || response.start_with?('<html>')
        logger.error(response)
        return {}
      end

      json = nil
      begin
        json = JSON.parse(response)
      rescue JSON::ParserError => ex
        logger.error(ex)
        return {}
      end

      json
    end

    def build_config_uri
      uri = URI(@data.config_route(@host))
      uri.query = QUERY_PARAMS
      uri
    end
  end
end
