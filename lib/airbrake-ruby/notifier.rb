module Airbrake
  # This class is reponsible for sending notices to Airbrake. It supports
  # synchronous and asynchronous delivery.
  #
  # @see Airbrake::Config The list of options
  # @since v1.0.0
  # @api private
  class Notifier
    # @return [String] the label to be prepended to the log output
    LOG_LABEL = '**Airbrake:'.freeze

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

      raise Airbrake::Error, @config.validation_error_message unless @config.valid?

      @context = {}

      @filter_chain = FilterChain.new
      add_default_filters

      @async_sender = AsyncSender.new(@config)
      @sync_sender = SyncSender.new(@config)
    end

    # @macro see_public_api_method
    def notify(exception, params = {}, &block)
      send_notice(exception, params, default_sender, &block)
    end

    # @macro see_public_api_method
    def notify_sync(exception, params = {}, &block)
      send_notice(exception, params, @sync_sender, &block).value
    end

    # @macro see_public_api_method
    def add_filter(filter = nil, &block)
      @filter_chain.add_filter(block_given? ? block : filter)
    end

    # @macro see_public_api_method
    def build_notice(exception, params = {})
      if @async_sender.closed?
        raise Airbrake::Error,
              "attempted to build #{exception} with closed Airbrake instance"
      end

      if exception.is_a?(Airbrake::Notice)
        exception[:params].merge!(params)
        exception
      else
        Notice.new(@config, convert_to_exception(exception), params.dup)
      end
    end

    # @macro see_public_api_method
    def close
      @async_sender.close
    end

    # @macro see_public_api_method
    def create_deploy(deploy_params)
      deploy_params[:environment] ||= @config.environment
      path = "api/v4/projects/#{@config.project_id}/deploys?key=#{@config.project_key}"
      promise = Airbrake::Promise.new
      @sync_sender.send(deploy_params, promise, URI.join(@config.host, path))
      promise
    end

    # @macro see_public_api_method
    def configured?
      @config.valid?
    end

    # @macro see_public_api_method
    def merge_context(context)
      @context.merge!(context)
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

    def send_notice(exception, params, sender)
      promise = Airbrake::Promise.new
      if @config.ignored_environment?
        return promise.reject("The '#{@config.environment}' environment is ignored")
      end

      notice = build_notice(exception, params)
      @filter_chain.refine(notice)
      yield notice if block_given? && !notice.ignored?

      return promise.reject("#{notice} was marked as ignored") if notice.ignored?

      sender.send(notice, promise)
    end

    def default_sender
      return @async_sender if @async_sender.has_workers?

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

    # rubocop:disable Metrics/AbcSize
    def add_default_filters
      if (whitelist_keys = @config.whitelist_keys).any?
        @filter_chain.add_filter(
          Airbrake::Filters::KeysWhitelist.new(@config.logger, whitelist_keys)
        )
      end

      if (blacklist_keys = @config.blacklist_keys).any?
        @filter_chain.add_filter(
          Airbrake::Filters::KeysBlacklist.new(@config.logger, blacklist_keys)
        )
      end

      @filter_chain.add_filter(Airbrake::Filters::ContextFilter.new(@context))
      @filter_chain.add_filter(
        Airbrake::Filters::ExceptionAttributesFilter.new(@config.logger)
      )

      return unless (root_directory = @config.root_directory)
      @filter_chain.add_filter(
        Airbrake::Filters::RootDirectoryFilter.new(root_directory)
      )

      @filter_chain.add_filter(
        Airbrake::Filters::GitRevisionFilter.new(root_directory)
      )
    end
    # rubocop:enable Metrics/AbcSize
  end
end
