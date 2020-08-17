module Airbrake
  class Config
    # Processor is a helper class, which is responsible for setting default
    # config values, default notifier filters and remote configuration changes.
    #
    # @since 5.0.0
    # @api private
    class Processor
      # @param [Airbrake::Config] config
      # @return [Airbrake::Config::Processor]
      def self.process(config)
        new(config).process
      end

      # @param [Airbrake::Config] config
      def initialize(config)
        @config = config
        @blocklist_keys = @config.blocklist_keys
        @allowlist_keys = @config.allowlist_keys
        @project_id = @config.project_id
      end

      # @param [Airbrake::NoticeNotifier] notifier
      # @return [void]
      def process_blocklist(notifier)
        return if @blocklist_keys.none?

        blocklist = Airbrake::Filters::KeysBlocklist.new(@blocklist_keys)
        notifier.add_filter(blocklist)
      end

      # @param [Airbrake::NoticeNotifier] notifier
      # @return [void]
      def process_allowlist(notifier)
        return if @allowlist_keys.none?

        allowlist = Airbrake::Filters::KeysAllowlist.new(@allowlist_keys)
        notifier.add_filter(allowlist)
      end

      # @return [Airbrake::RemoteSettings]
      def process_remote_configuration
        return unless @project_id

        RemoteSettings.poll(
          @project_id,
          @config.remote_config_host,
          &method(:poll_callback)
        )
      end

      # @param [Airbrake::NoticeNotifier] notifier
      # @return [void]
      def add_filters(notifier)
        return unless @config.root_directory

        [
          Airbrake::Filters::RootDirectoryFilter,
          Airbrake::Filters::GitRevisionFilter,
          Airbrake::Filters::GitRepositoryFilter,
          Airbrake::Filters::GitLastCheckoutFilter,
        ].each do |filter|
          next if notifier.has_filter?(filter)

          notifier.add_filter(filter.new(@config.root_directory))
        end
      end

      # @param [Airbrake::RemoteSettings::SettingsData] data
      # @return [void]
      def poll_callback(data)
        @config.logger.debug(
          "#{LOG_LABEL} applying remote settings: #{data.to_h}",
        )

        @config.error_host = data.error_host if data.error_host
        @config.apm_host = data.apm_host if data.apm_host

        @config.error_notifications = data.error_notifications?
        @config.performance_stats = data.performance_stats?
      end
    end
  end
end
