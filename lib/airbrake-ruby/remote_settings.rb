module Airbrake
  # RemoteSettings polls the remote config of the passed project at fixed
  # intervals. The fetched config is yielded as a callback parameter so that the
  # invoker can define read config values.
  #
  # @example Disable/enable error notifications based on the remote value
  #   RemoteSettings.new do |data|
  #     config.error_notifications = data.error_notifications?
  #   end
  #
  # @since ?.?.?
  # @api private
  class RemoteSettings
    include Airbrake::Loggable

    # Polls remote config of the given project.
    #
    # @param [Integer] project_id
    # @yield [data]
    # @yieldparam data [Airbrake::RemoteSettings::SettingsData]
    # @return [Airbrake::RemoteSettings]
    def self.poll(project_id, &block)
      new(project_id, &block).poll
    end

    # @param [Integer] project_id
    # @yield [data]
    # @yieldparam data [Airbrake::RemoteSettings::SettingsData]
    def initialize(project_id, &block)
      @data = SettingsData.new(project_id, {})
      @block = block
      @poll = nil
    end

    # Polls remote config of the given project in background.
    #
    # @return [self]
    def poll
      @poll ||= Thread.new do
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
        response = Net::HTTP.get(URI(@data.config_route))
      rescue StandardError => ex
        logger.error(ex)
        return {}
      end

      # AWS S3 API returns XML when request is not valid. In this case we just
      # print the returned body and exit the method.
      if response.start_with?('<?xml ')
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
  end
end
