module Airbrake
  # NoticeNotifier is reponsible for sending notices to Airbrake. It supports
  # synchronous and asynchronous delivery.
  #
  # @see Airbrake::Config The list of options
  # @since v1.0.0
  # @api public
  class NoticeNotifier
    # @return [Array<Class>] filters to be executed first
    DEFAULT_FILTERS = [
      Airbrake::Filters::SystemExitFilter,
      Airbrake::Filters::GemRootFilter

      # Optional filters (must be included by users):
      # Airbrake::Filters::ThreadFilter
    ].freeze

    include Inspectable
    include Loggable

    def initialize
      @config = Airbrake::Config.instance
      @context = {}
      @filter_chain = FilterChain.new
      @async_sender = AsyncSender.new
      @sync_sender = SyncSender.new

      add_default_filters
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
        Notice.new(convert_to_exception(exception), params.dup)
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
      promise = @config.check_configuration
      return promise if promise.rejected?

      notice = build_notice(exception, params)
      yield notice if block_given?
      @filter_chain.refine(notice)

      promise = Airbrake::Promise.new
      return promise.reject("#{notice} was marked as ignored") if notice.ignored?

      sender.send(notice, promise)
    end

    def default_sender
      return @async_sender if @async_sender.has_workers?

      logger.warn(
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
      DEFAULT_FILTERS.each { |f| add_filter(f.new) }

      if (whitelist_keys = @config.whitelist_keys).any?
        add_filter(Airbrake::Filters::KeysWhitelist.new(whitelist_keys))
      end

      if (blacklist_keys = @config.blacklist_keys).any?
        add_filter(Airbrake::Filters::KeysBlacklist.new(blacklist_keys))
      end

      add_filter(Airbrake::Filters::ContextFilter.new(@context))
      add_filter(Airbrake::Filters::ExceptionAttributesFilter.new)

      return unless (root_directory = @config.root_directory)
      [
        Airbrake::Filters::RootDirectoryFilter,
        Airbrake::Filters::GitRevisionFilter,
        Airbrake::Filters::GitRepositoryFilter
      ].each do |filter|
        add_filter(filter.new(root_directory))
      end

      add_filter(
        Airbrake::Filters::GitLastCheckoutFilter.new(root_directory)
      )
    end
    # rubocop:enable Metrics/AbcSize
  end
end
