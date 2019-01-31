module Airbrake
  # NoticeNotifier is reponsible for sending notices to Airbrake. It supports
  # synchronous and asynchronous delivery.
  #
  # @see Airbrake::Config The list of options
  # @since v1.0.0
  # @api private
  class NoticeNotifier
    # @return [String] the label to be prepended to the log output
    LOG_LABEL = '**Airbrake:'.freeze

    # @return [String] inspect output template
    INSPECT_TEMPLATE =
      "#<#{self}:0x%<id>s project_id=\"%<project_id>s\" " \
      "project_key=\"%<project_key>s\" " \
      "host=\"%<host>s\" filter_chain=%<filter_chain>s>".freeze

    # Creates a new notice notifier with the given config options.
    #
    # @example
    #   config = Airbrake::Config.new
    #   config.project_id = 123
    #   config.project_key = '321'
    #   notice_notifier = Airbrake::NoticeNotifier.new(config)
    #
    # @param [Airbrake::Config] config
    def initialize(config)
      @config =
        if config.is_a?(Config)
          config
        else
          loc = caller_locations(1..1).first
          signature = "#{self.class.name}##{__method__}"
          warn(
            "#{loc.path}:#{loc.lineno}: warning: passing a Hash to #{signature} " \
            'is deprecated. Pass `Airbrake::Config` instead'
          )
          Config.new(config)
        end

      @context = {}
      @filter_chain = FilterChain.new(@config, @context)
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
    def delete_filter(filter_class)
      @filter_chain.delete_filter(filter_class)
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
    def configured?
      @config.valid?
    end

    # @macro see_public_api_method
    def merge_context(context)
      @context.merge!(context)
    end

    # @return [String] customized inspect to lessen the amount of clutter
    def inspect
      format(
        INSPECT_TEMPLATE,
        id: (object_id << 1).to_s(16).rjust(16, '0'),
        project_id: @config.project_id,
        project_key: @config.project_key,
        host: @config.host,
        filter_chain: @filter_chain.inspect
      )
    end

    # @return [String] {#inspect} for PrettyPrint
    def pretty_print(q)
      q.text("#<#{self.class}:0x#{(object_id << 1).to_s(16).rjust(16, '0')} ")
      q.text(
        "project_id=\"#{@config.project_id}\" project_key=\"#{@config.project_key}\" " \
        "host=\"#{@config.host}\" filter_chain="
      )
      q.pp(@filter_chain)
      q.text('>')
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
      yield notice if block_given?
      @filter_chain.refine(notice)

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
  end
end
