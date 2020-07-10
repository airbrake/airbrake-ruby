module Airbrake
  class RemoteSettings
    # SettingsData is a container, which wraps JSON payload returned by the
    # remote settings API. It exposes the payload via convenient methods and
    # also ensures that in case some data from the payload is missing, a default
    # value would be returned instead.
    #
    # @example
    #   # Create the object and pass initial data (empty hash).
    #   settings_data = SettingsData.new({})
    #
    #   settings_data.interval #=> 600
    #
    # @since ?.?.?
    # @api private
    class SettingsData
      # @return [Integer] how frequently we should poll the config API
      DEFAULT_INTERVAL = 600

      # @return [String] API version of the S3 API to poll
      API_VER = '2020-06-18'.freeze

      # @return [String] what URL to poll
      CONFIG_ROUTE_PATTERN =
        'https://%<bucket>s.s3.amazonaws.com/' \
        "#{API_VER}/config/%<project_id>s/config.json".freeze

      # @return [Hash{Symbol=>String}] the hash of all supported settings where
      #   the value is the name of the setting returned by the API
      SETTINGS = {
        errors: 'errors',
        apm: 'apm',
      }.freeze

      # @param [Integer] project_id
      # @param [Hash{String=>Object}] data
      def initialize(project_id, data)
        @project_id = project_id
        @data = data
      end

      # Merges the given +hash+ with internal data.
      #
      # @param [Hash{String=>Object}] hash
      # @return [self]
      def merge!(hash)
        @data.merge!(hash)

        self
      end

      # @return [Integer] how frequently we should poll for the config
      def interval
        return DEFAULT_INTERVAL if !@data.key?('poll_sec') || !@data['poll_sec']

        @data['poll_sec'] > 0 ? @data['poll_sec'] : DEFAULT_INTERVAL
      end

      # @return [String] where the config is stored on S3.
      def config_route
        if !@data.key?('config_route') || !@data['config_route']
          return format(
            CONFIG_ROUTE_PATTERN,
            bucket: 'staging-notifier-configs',
            project_id: @project_id,
          )
        end

        @data['config_route']
      end

      # @return [Boolean] whether error notifications are enabled
      def error_notifications?
        return true unless (s = find_setting(SETTINGS[:errors]))

        s['enabled']
      end

      # @return [Boolean] whether APM is enabled
      def performance_stats?
        return true unless (s = find_setting(SETTINGS[:apm]))

        s['enabled']
      end

      # @return [Hash{String=>Object}] raw representation of JSON payload
      def to_h
        @data.dup
      end

      private

      def find_setting(name)
        return unless @data.key?('settings')

        @data['settings'].find { |s| s['name'] == name }
      end
    end
  end
end
