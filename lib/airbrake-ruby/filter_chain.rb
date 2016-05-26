module Airbrake
  ##
  # Represents the mechanism for filtering notices. Defines a few default
  # filters.
  # @see Airbrake.add_filter
  class FilterChain
    ##
    # Replaces paths to gems with a placeholder.
    # @return [Proc]
    GEM_ROOT_FILTER = proc do |notice|
      return unless defined?(Gem)

      notice[:errors].each do |error|
        Gem.path.each do |gem_path|
          error[:backtrace].each do |frame|
            frame[:file].sub!(/\A#{gem_path}/, '[GEM_ROOT]'.freeze)
          end
        end
      end
    end

    ##
    # Skip over SystemExit exceptions, because they're just noise.
    # @return [Proc]
    SYSTEM_EXIT_FILTER = proc do |notice|
      if notice[:errors].any? { |error| error[:type] == 'SystemExit' }
        notice.ignore!
      end
    end

    ##
    # @param [Airbrake::Config] config
    def initialize(config)
      @filters = []

      [SYSTEM_EXIT_FILTER, GEM_ROOT_FILTER].each do |filter|
        add_filter(filter)
      end

      root_directory = config.root_directory
      add_filter(root_directory_filter(root_directory)) if root_directory
    end

    ##
    # Adds a filter to the filter chain.
    # @param [#call] filter The filter object (proc, class, module, etc)
    def add_filter(filter)
      @filters << filter
    end

    ##
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

    private

    def root_directory_filter(root_directory)
      proc do |notice|
        notice[:errors].each do |error|
          error[:backtrace].each do |frame|
            frame[:file].sub!(/\A#{root_directory}/, '[PROJECT_ROOT]'.freeze)
          end
        end
      end
    end
  end
end
