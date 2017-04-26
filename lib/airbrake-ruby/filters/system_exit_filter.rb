module Airbrake
  module Filters
    ##
    # Skip over SystemExit exceptions, because they're just noise.
    class SystemExitFilter
      ##
      # @return [String]
      SYSTEM_EXIT_TYPE = 'SystemExit'.freeze

      def call(notice)
        return if notice[:errors].none? { |error| error[:type] == SYSTEM_EXIT_TYPE }
        notice.ignore!
      end
    end
  end
end
