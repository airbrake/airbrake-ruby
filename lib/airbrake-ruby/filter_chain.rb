module Airbrake
  # Represents the mechanism for filtering notices. Defines a few default
  # filters.
  #
  # @see Airbrake.add_filter
  # @api private
  # @since v1.0.0
  class FilterChain
    # @return [Array<Class>] filters to be executed first
    DEFAULT_FILTERS = [
      Airbrake::Filters::SystemExitFilter,
      Airbrake::Filters::GemRootFilter

      # Optional filters (must be included by users):
      # Airbrake::Filters::ThreadFilter
    ].freeze

    # @return [Integer]
    DEFAULT_WEIGHT = 0

    def initialize(config, context)
      @config = config
      @context = context
      @filters = []
      DEFAULT_FILTERS.each { |f| add_filter(f.new) }
      add_default_filters
    end

    # Adds a filter to the filter chain. Sorts filters by weight.
    #
    # @param [#call] filter The filter object (proc, class, module, etc)
    # @return [void]
    def add_filter(filter)
      @filters = (@filters << filter).sort_by do |f|
        f.respond_to?(:weight) ? f.weight : DEFAULT_WEIGHT
      end.reverse!
    end

    # Deletes a filter from the the filter chain.
    #
    # @param [Class] filter_class The class of the filter you want to delete
    # @return [void]
    # @since v3.1.0
    def delete_filter(filter_class)
      index = @filters.index { |f| f.class.name == filter_class.name }
      @filters.delete_at(index) if index
    end

    # Applies all the filters in the filter chain to the given notice. Does not
    # filter ignored notices.
    #
    # @param [Airbrake::Notice] notice The notice to be filtered
    # @return [void]
    def refine(notice)
      @filters.each do |filter|
        break if notice.ignored?
        filter.call(notice)
      end
    end

    # @return [String] customized inspect to lessen the amount of clutter
    def inspect
      @filters.map(&:class)
    end

    # @return [String] {#inspect} for PrettyPrint
    def pretty_print(q)
      q.text('[')

      # Make nesting of the first element consistent on JRuby and MRI.
      q.nest(2) { q.breakable }

      q.nest(2) do
        q.seplist(@filters) { |f| q.pp(f.class) }
      end
      q.text(']')
    end

    private

    # rubocop:disable Metrics/AbcSize
    def add_default_filters
      if (whitelist_keys = @config.whitelist_keys).any?
        add_filter(
          Airbrake::Filters::KeysWhitelist.new(@config.logger, whitelist_keys)
        )
      end

      if (blacklist_keys = @config.blacklist_keys).any?
        add_filter(
          Airbrake::Filters::KeysBlacklist.new(@config.logger, blacklist_keys)
        )
      end

      add_filter(Airbrake::Filters::ContextFilter.new(@context))
      add_filter(Airbrake::Filters::ExceptionAttributesFilter.new(@config.logger))

      return unless (root_directory = @config.root_directory)
      [
        Airbrake::Filters::RootDirectoryFilter,
        Airbrake::Filters::GitRevisionFilter,
        Airbrake::Filters::GitRepositoryFilter
      ].each do |filter|
        add_filter(filter.new(root_directory))
      end

      add_filter(
        Airbrake::Filters::GitLastCheckoutFilter.new(@config.logger, root_directory)
      )
    end
    # rubocop:enable Metrics/AbcSize
  end
end
