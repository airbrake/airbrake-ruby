source 'https://rubygems.org'
gemspec

gem 'rubocop', '~> 1.16', require: false
gem 'rubocop-rake', '~> 0.5', require: false
gem 'rubocop-rspec', '~> 2.3', require: false

gem 'simplecov', '~> 0.16', require: false

gem 'webrick', '~> 1.7' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0')
gem 'yard', '0.9.28'
# ostruct, logger, and rdoc were extracted from stdlib in Ruby 4; include them for docs/tools that require them
# Pin rdoc to a version compatible with yard 0.9.28 (newer rdoc changed the API)
gem 'ostruct'
gem 'logger'
gem 'rdoc', '< 7.0'
