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
    # @return [String] the namespace for filters, which are executed first,
    #   before any other filters
    LIB_NAMESPACE = '#<Airbrake::'.freeze

    ##
    # @return [Array<Class>] filters to be executed first
    DEFAULT_FILTERS = [
      Airbrake::Filters::SystemExitFilter,
      Airbrake::Filters::GemRootFilter,
      Airbrake::Filters::ThreadFilter
    ].freeze

    ##
    # @return [Array<Class>] filters to be executed last
    POST_FILTERS = [
      Airbrake::Filters::KeysBlacklist,
      Airbrake::Filters::KeysWhitelist
    ].freeze

    ##
    # @param [Airbrake::Config] config
    def initialize(config)
      @filters = DEFAULT_FILTERS.map(&:new)
      @post_filters = []

      root_directory = config.root_directory
      return unless root_directory

      @filters << Airbrake::Filters::RootDirectoryFilter.new(root_directory)
    end

    ##
    # Adds a filter to the filter chain.
    #
    # @param [#call] filter The filter object (proc, class, module, etc)
    # @return [void]
    def add_filter(filter)
      return @post_filters << filter if POST_FILTERS.include?(filter.class)
      return @filters << filter unless filter.to_s.start_with?(LIB_NAMESPACE)

      i = @filters.rindex { |f| f.to_s.start_with?(LIB_NAMESPACE) }
      @filters.insert(i + 1, filter) if i
    end

    ##
    # Applies all the filters in the filter chain to the given notice. Does not
    # filter ignored notices.
    #
    # @param [Airbrake::Notice] notice The notice to be filtered
    # @return [void]
    def refine(notice)
      (@filters + @post_filters).each do |filter|
        break if notice.ignored?
        filter.call(notice)
      end
    end
  end
end
