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

    def initialize
      @filters = []
      DEFAULT_FILTERS.each { |f| add_filter(f.new) }
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
  end
end
