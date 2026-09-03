require './lib/airbrake-ruby/version'

Gem::Specification.new do |s|
  s.name        = 'airbrake-ruby'
  s.version     = Airbrake::AIRBRAKE_RUBY_VERSION.dup
  s.summary     = 'Ruby notifier for https://airbrake.io'
  s.description = <<DESC
Airbrake Ruby is a plain Ruby notifier for Airbrake (https://airbrake.io), the
leading exception reporting service. Airbrake Ruby provides minimalist API that
enables the ability to send any Ruby exception to the Airbrake dashboard. The
library is extremely lightweight and it perfectly suits plain Ruby applications.
For apps that are built with Rails, Sinatra or any other Rack-compliant web
framework we offer the airbrake gem (https://github.com/airbrake/airbrake). It
has additional features such as reporting of any unhandled exceptions
automatically, integrations with Resque, Sidekiq, Delayed Job and many more.
DESC
  s.author      = 'Airbrake Technologies, Inc.'
  s.email       = 'support@airbrake.io'
  s.homepage    = 'https://airbrake.io'
  s.license     = 'MIT'

  s.require_path = 'lib'
  s.files        = ['lib/airbrake-ruby.rb', *Dir.glob('lib/**/*')]

  s.required_ruby_version = '>= 3.0'
  s.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  # Ensure Gem is loaded for comparisons
  require 'rubygems' unless defined?(Gem)

  # These libraries were extracted from the standard library in newer Rubies.
  # Declare them unconditionally so gem metadata is valid regardless of the
  # Ruby version used to build the gem.
  s.add_dependency 'base64'
  s.add_dependency 'logger'

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1.2'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'webmock', '~> 3.8'
  s.add_development_dependency 'benchmark-ips', '~> 2'
  s.add_development_dependency 'yard', '~> 0.9'
end
