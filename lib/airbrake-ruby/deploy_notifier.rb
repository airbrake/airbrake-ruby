module Airbrake
  # DeployNotifier sends deploy information to Airbrake. The information
  # consists of:
  # - environment
  # - username
  # - repository
  # - revision
  # - version
  # @since v3.2.0
  class DeployNotifier
    def initialize(user_config)
      @config = (user_config.is_a?(Config) ? user_config : Config.new(user_config))

      raise Airbrake::Error, @config.validation_error_message unless @config.valid?

      @sender = SyncSender.new(@config)
    end

    # @see Airbrake.create_deploy
    def notify(deploy_info, promise = Airbrake::Promise.new)
      if @config.ignored_environment?
        return promise.reject("The '#{@config.environment}' environment is ignored")
      end

      deploy_info[:environment] ||= @config.environment
      @sender.send(
        deploy_info,
        promise,
        URI.join(@config.host, "api/v4/projects/#{@config.project_id}/deploys")
      )

      promise
    end
  end
end
