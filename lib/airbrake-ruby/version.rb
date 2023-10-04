# We use Semantic Versioning v2.0.0
# More information: http://semver.org/
module Airbrake
  # @return [String] the library version
  # @api public
  AIRBRAKE_RUBY_VERSION = '6.2.2'.freeze

  # @return [Hash{Symbol=>String}] the information about the notifier library
  # @since v5.0.0
  # @api public
  NOTIFIER_INFO = {
    name: 'airbrake-ruby'.freeze,
    version: Airbrake::AIRBRAKE_RUBY_VERSION,
    url: 'https://github.com/airbrake/airbrake-ruby'.freeze,
  }.freeze
end
