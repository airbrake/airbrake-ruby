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

  s.required_ruby_version = '>= 2.5'
  s.metadata = {
    'rubygems_mfa_required' => 'true',
  }

  s.add_dependency 'base64', '~> 0.1'

  if defined?(JRuby)
    s.add_dependency 'rbtree-jruby', '~> 0.2'
  else
    s.add_dependency 'rbtree3', '~> 0.6'
  end

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rspec-its', '~> 1.2'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'pry', '~> 0'
  s.add_development_dependency 'webmock', '~> 3.8'
  s.add_development_dependency 'benchmark-ips', '~> 2'
  s.add_development_dependency 'yard', '~> 0.9'
end
