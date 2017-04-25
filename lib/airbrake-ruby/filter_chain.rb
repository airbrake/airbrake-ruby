module Airbrake
  ##
  # Represents the mechanism for filtering notices. Defines a few default
  # filters.
  #
  # @see Airbrake.add_filter
  # @api private
  # @since v1.0.0
  class FilterChain
    ##
    # Filters to be executed last. By this time all permutations on a notice
    # should be done, so the final step is to blacklist/whitelist keys.
    # @return [Array<Class>]
    KEYS_FILTERS = [
      Airbrake::Filters::KeysBlacklist,
      Airbrake::Filters::KeysWhitelist
    ].freeze

    ##
    # @param [Airbrake::Config] config
    def initialize(config)
      @filters = []
      @keys_filters = []

      [Airbrake::Filters::SystemExitFilter,
       Airbrake::Filters::GemRootFilter].each do |filter|
        add_filter(filter.new)
      end

      root_directory = config.root_directory
      return unless root_directory

      add_filter(Airbrake::Filters::RootDirectoryFilter.new(root_directory))
    end

    ##
    # Adds a filter to the filter chain.
    # @param [#call] filter The filter object (proc, class, module, etc)
    def add_filter(filter)
      return @keys_filters << filter if KEYS_FILTERS.include?(filter.class)
      @filters << filter
    end

    ##
    # Applies all the filters in the filter chain to the given notice. Does not
    # filter ignored notices.
    #
    # @param [Airbrake::Notice] notice The notice to be filtered
    # @return [void]
    def refine(notice)
      (@filters + @keys_filters).each do |filter|
        break if notice.ignored?
        filter.call(notice)
      end
    end
  end
end
