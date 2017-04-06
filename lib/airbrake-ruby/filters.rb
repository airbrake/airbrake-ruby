module Airbrake
  ##
  # Represents a namespace for default Airbrake Ruby filters.
  module Filters
    ##
    # @return [Array<Symbol>] parts of a Notice's payload that can be modified
    #   by various filters
    FILTERABLE_KEYS = %i[environment session params].freeze
  end
end
