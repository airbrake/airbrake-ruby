module Airbrake
  class Config
    # Validates values of {Airbrake::Config} options.
    #
    # @api private
    # @since v1.5.0
    class Validator
      # @return [String]
      REQUIRED_KEY_MSG = ':project_key is required'.freeze

      # @return [String]
      REQUIRED_ID_MSG = ':project_id is required'.freeze

      # @return [String]
      WRONG_ENV_TYPE_MSG = "the 'environment' option must be configured " \
                           "with a Symbol (or String), but '%s' was provided: " \
                           '%s'.freeze

      # @return [Array<Class>] the list of allowed types to configure the
      #   environment option
      VALID_ENV_TYPES = [NilClass, String, Symbol].freeze

      # @return [String] error message, if validator was able to find any errors
      #   in the config
      attr_reader :error_message

      # Validates given config and stores error message, if any errors were
      # found.
      #
      # @param config [Airbrake::Config] the config to validate
      def initialize(config)
        @config = config
        @error_message = nil
      end

      # @return [Boolean]
      def valid_project_id?
        valid = @config.project_id.to_i > 0
        @error_message = REQUIRED_ID_MSG unless valid
        valid
      end

      # @return [Boolean]
      def valid_project_key?
        valid = @config.project_key.is_a?(String) && !@config.project_key.empty?
        @error_message = REQUIRED_KEY_MSG unless valid
        valid
      end

      # @return [Boolean]
      def valid_environment?
        environment = @config.environment
        valid = VALID_ENV_TYPES.any? { |type| environment.is_a?(type) }

        unless valid
          @error_message = format(WRONG_ENV_TYPE_MSG, environment.class, environment)
        end

        valid
      end
    end
  end
end
