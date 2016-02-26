module Airbrake
  ##
  # This class is reponsible for sending notices to Airbrake. It supports
  # synchronous and asynchronous delivery.
  #
  # @see Airbrake::Config The list of options
  # @api private
  # @since v5.0.0
  class Notifier
    ##
    # Creates a new Airbrake notifier with the given config options.
    #
    # @example Configuring with a Hash
    #   airbrake = Airbrake.new(project_id: 123, project_key: '321')
    #
    # @example Configuring with an Airbrake::Config
    #   config = Airbrake::Config.new
    #   config.project_id = 123
    #   config.project_key = '321'
    #   airbake = Airbrake.new(config)
    #
    # @param [Hash, Airbrake::Config] user_config The config that contains
    #   information about how the notifier should operate
    # @raise [Airbrake::Error] when either +project_id+ or +project_key+
    #   is missing (or both)
    def initialize(user_config)
      @config = (user_config.is_a?(Config) ? user_config : Config.new(user_config))

      unless [@config.project_id, @config.project_key].all?
        raise Airbrake::Error, 'both :project_id and :project_key are required'
      end

      @filter_chain = FilterChain.new(@config)
      @async_sender = AsyncSender.new(@config)
      @sync_sender = SyncSender.new(@config)
    end

    ##
    # @!macro see_public_api_method
    #   @see Airbrake.$0

    ##
    # @macro see_public_api_method
    def notify(exception, params = {})
      send_notice(exception, params)
      nil
    end

    ##
    # @macro see_public_api_method
    def notify_sync(exception, params = {})
      send_notice(exception, params, @sync_sender)
    end

    ##
    # @macro see_public_api_method
    def add_filter(filter = nil, &block)
      @filter_chain.add_filter(block_given? ? block : filter)
    end

    ##
    # @macro see_public_api_method
    def whitelist_keys(keys)
      add_filter(Filters::KeysWhitelist.new(*keys))
    end

    ##
    # @macro see_public_api_method
    def blacklist_keys(keys)
      add_filter(Filters::KeysBlacklist.new(*keys))
    end

    ##
    # @macro see_public_api_method
    def build_notice(exception, params = {})
      if @async_sender.closed?
        raise Airbrake::Error,
              "attempted to build #{exception} with closed Airbrake instance"
      end

      if exception.is_a?(Airbrake::Notice)
        exception
      else
        Notice.new(@config, convert_to_exception(exception), params)
      end
    end

    ##
    # @macro see_public_api_method
    def close
      @async_sender.close
    end

    ##
    # @macro see_public_api_method
    def create_deploy(deploy_params)
      deploy_params[:environment] ||= @config.environment

      host = @config.endpoint.to_s.split(@config.endpoint.path).first
      path = "/api/v4/projects/#{@config.project_id}/deploys?key=#{@config.project_key}"

      @sync_sender.send(deploy_params, URI.join(host, path))
    end

    private

    def convert_to_exception(ex)
      if ex.is_a?(Exception) || Backtrace.java_exception?(ex)
        # Manually created exceptions don't have backtraces, so we create a fake
        # one, whose first frame points to the place where Airbrake was called
        # (normally via `notify`).
        ex.set_backtrace(clean_backtrace) unless ex.backtrace
        return ex
      end

      e = RuntimeError.new(ex.to_s)
      e.set_backtrace(clean_backtrace)
      e
    end

    def send_notice(exception, params, sender = default_sender)
      notice = build_notice(exception, params)
      @filter_chain.refine(notice)
      return if notice.ignored?

      sender.send(notice)
    end

    def default_sender
      return @async_sender if @config.always_async || @async_sender.has_workers?

      @config.logger.warn(
        "#{LOG_LABEL} falling back to sync delivery because there are no " \
        "running async workers"
      )
      @sync_sender
    end

    def clean_backtrace
      caller_copy = Kernel.caller
      clean_bt = caller_copy.drop_while { |frame| frame.include?('/lib/airbrake') }

      # If true, then it's likely an internal library error. In this case return
      # at least some backtrace to simplify debugging.
      return caller_copy if clean_bt.empty?
      clean_bt
    end
  end
end
