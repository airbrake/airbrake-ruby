require 'rspec/core/rake_task'
require 'rubygems/package_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

# rubocop:disable Security/Eval
def modify_base_gemspec
  eval(File.read('airbrake-ruby.gemspec')).tap { |s| yield s }
end
# rubocop:enable Security/Eval

namespace :ruby do
  spec = modify_base_gemspec do |s|
    # We keep this dependency in Gemfile, so we can run CI builds. When we
    # generate gems, duplicate dependencies are not allowed.
    s.dependencies.delete_if { |d| d.name == 'rbtree-jruby' || 'rbtree3' }

    s.platform = Gem::Platform::RUBY
    s.add_dependency('rbtree3', '~> 0.5')
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end
end

namespace :jruby do
  spec = modify_base_gemspec do |s|
    # We keep this dependency in Gemfile, so we can run CI builds. When we
    # generate gems, duplicate dependencies are not allowed.
    s.dependencies.delete_if { |d| d.name == 'rbtree-jruby' || 'rbtree3' }

    s.platform = 'java'
    s.add_dependency('rbtree-jruby', '~> 0.2')
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end
end

desc 'Build all platform gems at once'
task gems: %w[ruby:gem jruby:gem]

desc 'Build and push platform gems'
task pushgems: :gems do
  chdir("#{File.dirname(__FILE__)}/pkg") do
    Dir['*.gem'].each { |gem| sh "gem push #{gem}" }
  end
end
