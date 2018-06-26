require 'net/https'
require 'logger'
require 'json'
require 'thread'
require 'set'
require 'socket'

require 'airbrake-ruby/version'
require 'airbrake-ruby/config'
require 'airbrake-ruby/config/validator'
require 'airbrake-ruby/promise'
require 'airbrake-ruby/sync_sender'
require 'airbrake-ruby/async_sender'
require 'airbrake-ruby/response'
require 'airbrake-ruby/nested_exception'
require 'airbrake-ruby/notice'
require 'airbrake-ruby/backtrace'
require 'airbrake-ruby/truncator'
require 'airbrake-ruby/filters/keys_filter'
require 'airbrake-ruby/filters/keys_whitelist'
require 'airbrake-ruby/filters/keys_blacklist'
require 'airbrake-ruby/filters/gem_root_filter'
require 'airbrake-ruby/filters/system_exit_filter'
require 'airbrake-ruby/filters/root_directory_filter'
require 'airbrake-ruby/filters/thread_filter'
require 'airbrake-ruby/filters/context_filter'
require 'airbrake-ruby/filters/exception_attributes_filter'
require 'airbrake-ruby/filters/dependency_filter'
require 'airbrake-ruby/filters/git_revision_filter'
require 'airbrake-ruby/filter_chain'
require 'airbrake-ruby/notifier'
require 'airbrake-ruby/code_hunk'
require 'airbrake-ruby/file_cache'

# This module defines the Airbrake API. The user is meant to interact with
# Airbrake via its public class methods. Before using the library, you must to
# {configure} the default notifier.
#
# The module supports multiple notifiers, each of which can be configured
# differently. By default, every method is invoked in context of the default
# notifier. To use a different notifier, you need to {configure} it first and
# pass the notifier's name as the last argument of the method you're calling.
#
# You can have as many notifiers as you want, but they must have unique names.
#
# @example Configuring multiple notifiers and using them
#   # Configure the default notifier.
#   Airbrake.configure do |c|
#     c.project_id = 113743
#     c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
#   end
#
#   # Configure a named notifier.
#   Airbrake.configure(:my_other_project) do |c|
#     c.project_id = 224854
#     c.project_key = '91ac5e4a37496026c6837f63276ed2b6'
#   end
#
#   # Send an exception via the default notifier.
#   Airbrake.notify('Oops!')
#
#   # Send an exception via other configured notifier.
#   params = {}
#   Airbrake[:my_other_project].notify('Oops', params)
#
# @see Airbrake::Notifier
# @since v1.0.0
module Airbrake
  # The general error that this library uses when it wants to raise.
  Error = Class.new(StandardError)

  # @return [String] the label to be prepended to the log output
  LOG_LABEL = '**Airbrake:'.freeze

  # @return [Boolean] true if current Ruby is Ruby 2.0.*. The result is used
  #   for special cases where we need to work around older implementations
  RUBY_20 = RUBY_VERSION.start_with?('2.0')

  # @return [Boolean] true if current Ruby is JRuby. The result is used for
  #  special cases where we need to work around older implementations
  JRUBY = (RUBY_ENGINE == 'jruby')

  # @!macro see_public_api_method
  #   @see Airbrake.$0

  # NilNotifier is a no-op notifier, which mimics +Airbrake::Notifier+ and
  # serves only for the purpose of making the library API easier to use.
  #
  # @since 2.1.0
  class NilNotifier
    # @macro see_public_api_method
    def notify(_exception, _params = {}, &block); end

    # @macro see_public_api_method
    def notify_sync(_exception, _params = {}, &block); end

    # @macro see_public_api_method
    def add_filter(_filter = nil, &_block); end

    # @macro see_public_api_method
    def build_notice(_exception, _params = {}); end

    # @macro see_public_api_method
    def close; end

    # @macro see_public_api_method
    def create_deploy(_deploy_params); end

    # @macro see_public_api_method
    def configured?
      false
    end

    # @macro see_public_api_method
    def merge_context(_context); end
  end

  # A Hash that holds all notifiers. The keys of the Hash are notifier
  # names, the values are Airbrake::Notifier instances. If a notifier is not
  # assigned to the hash, then it returns a null object (NilNotifier).
  @notifiers = Hash.new(NilNotifier.new)

  class << self
    # Retrieves configured notifiers.
    #
    # @example
    #   Airbrake[:my_notifier].notify('oops')
    #
    # @param [Symbol] notifier_name the name of the notifier you want to use
    # @return [Airbrake::Notifier, NilClass]
    # @since v1.8.0
    def [](notifier_name)
      @notifiers[notifier_name]
    end

    # Configures a new +notifier+ with the given name. If the name is not given,
    # configures the default notifier.
    #
    # @example Configuring the default notifier
    #   Airbrake.configure do |c|
    #     c.project_id = 113743
    #     c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
    #   end
    #
    # @example Configuring a named notifier
    #   # Configure a new Airbrake instance and
    #   # assign +:my_other_project+ as its name.
    #   Airbrake.configure(:my_other_project) do |c|
    #     c.project_id = 224854
    #     c.project_key = '91ac5e4a37496026c6837f63276ed2b6'
    #   end
    #
    # @param [Symbol] notifier_name the name to be associated with the notifier
    # @yield [config] The configuration object
    # @yieldparam config [Airbrake::Config]
    # @return [void]
    # @raise [Airbrake::Error] when trying to reconfigure already
    #   existing notifier
    # @note There's no way to reconfigure a notifier
    # @note There's no way to read config values outside of this library
    def configure(notifier_name = :default)
      yield config = Airbrake::Config.new

      if @notifiers.key?(notifier_name)
        raise Airbrake::Error,
              "the '#{notifier_name}' notifier was already configured"
      else
        @notifiers[notifier_name] = Notifier.new(config)
      end
    end

    # @return [Boolean] true if the notifier was configured, false otherwise
    # @since 2.3.0
    def configured?
      @notifiers[:default].configured?
    end

    # Sends an exception to Airbrake asynchronously.
    #
    # @example Sending an exception
    #   Airbrake.notify(RuntimeError.new('Oops!'))
    # @example Sending a string
    #   # Converted to RuntimeError.new('Oops!') internally
    #   Airbrake.notify('Oops!')
    # @example Sending a Notice
    #   notice = airbrake.build_notice(RuntimeError.new('Oops!'))
    #   airbrake.notify(notice)
    #
    # @param [Exception, String, Airbrake::Notice] exception The exception to be
    #   sent to Airbrake
    # @param [Hash] params The additional payload to be sent to Airbrake. Can
    #   contain any values. The provided values will be displayed in the Params
    #   tab in your project's dashboard
    # @yield [notice] The notice to filter
    # @yieldparam [Airbrake::Notice]
    # @yieldreturn [void]
    # @return [Airbrake::Promise]
    # @see .notify_sync
    def notify(exception, params = {}, &block)
      @notifiers[:default].notify(exception, params, &block)
    end

    # Sends an exception to Airbrake synchronously.
    #
    # @example
    #   Airbrake.notify_sync('App crashed!')
    #   #=> {"id"=>"123", "url"=>"https://airbrake.io/locate/321"}
    #
    # @param [Exception, String, Airbrake::Notice] exception The exception to be
    #   sent to Airbrake
    # @param [Hash] params The additional payload to be sent to Airbrake. Can
    #   contain any values. The provided values will be displayed in the Params
    #   tab in your project's dashboard
    # @yield [notice] The notice to filter
    # @yieldparam [Airbrake::Notice]
    # @yieldreturn [void]
    # @return [Hash{String=>String}] the reponse from the server
    # @see .notify
    def notify_sync(exception, params = {}, &block)
      @notifiers[:default].notify_sync(exception, params, &block)
    end

    # Runs a callback before {.notify} or {.notify_sync} kicks in. This is
    # useful if you want to ignore specific notices or filter the data the
    # notice contains.
    #
    # @example Ignore all notices
    #   Airbrake.add_filter(&:ignore!)
    # @example Ignore based on some condition
    #   Airbrake.add_filter do |notice|
    #     notice.ignore! if notice[:error_class] == 'StandardError'
    #   end
    # @example Ignore with help of a class
    #   class MyFilter
    #     def call(notice)
    #       # ...
    #     end
    #   end
    #
    #   Airbrake.add_filter(MyFilter.new)
    #
    # @param [#call] filter The filter object
    # @yield [notice] The notice to filter
    # @yieldparam [Airbrake::Notice]
    # @yieldreturn [void]
    # @return [void]
    # @note Once a filter was added, there's no way to delete it
    def add_filter(filter = nil, &block)
      @notifiers[:default].add_filter(filter, &block)
    end

    # Builds an Airbrake notice. This is useful, if you want to add or modify a
    # value only for a specific notice. When you're done modifying the notice,
    # send it with {.notify} or {.notify_sync}.
    #
    # @example
    #   notice = airbrake.build_notice('App crashed!')
    #   notice[:params][:username] = user.name
    #   airbrake.notify_sync(notice)
    #
    # @param [Exception] exception The exception on top of which the notice
    #   should be built
    # @param [Hash] params The additional params attached to the notice
    # @return [Airbrake::Notice] the notice built with help of the given
    #   arguments
    def build_notice(exception, params = {})
      @notifiers[:default].build_notice(exception, params)
    end

    # Makes the notifier a no-op, which means you cannot use the {.notify} and
    # {.notify_sync} methods anymore. It also stops the notifier's worker
    # threads.
    #
    # @example
    #   Airbrake.close
    #   Airbrake.notify('App crashed!') #=> raises Airbrake::Error
    #
    # @return [void]
    def close
      @notifiers[:default].close
    end

    # Pings the Airbrake Deploy API endpoint about the occurred deploy. This
    # method is used by the airbrake gem for various integrations.
    #
    # @param [Hash{Symbol=>String}] deploy_params The params for the API
    # @option deploy_params [Symbol] :environment
    # @option deploy_params [Symbol] :username
    # @option deploy_params [Symbol] :repository
    # @option deploy_params [Symbol] :revision
    # @option deploy_params [Symbol] :version
    # @return [void]
    def create_deploy(deploy_params)
      @notifiers[:default].create_deploy(deploy_params)
    end

    # Merges +context+ with the current context.
    #
    # The context will be attached to the notice object upon a notify call and
    # cleared after it's attached. The context data is attached to the
    # `params/airbrake_context` key.
    #
    # @example
    #   class MerryGrocer
    #     def load_fruits(fruits)
    #       Airbrake.merge_context(fruits: fruits)
    #     end
    #
    #     def deliver_fruits
    #       Airbrake.notify('fruitception')
    #     end
    #
    #     def load_veggies(veggies)
    #       Airbrake.merge_context(veggies: veggies)
    #     end
    #
    #     def deliver_veggies
    #       Airbrake.notify('veggieboom!')
    #     end
    #   end
    #
    #   grocer = MerryGrocer.new
    #
    #   # Load some fruits to the context.
    #   grocer.load_fruits(%w(mango banana apple))
    #
    #   # Deliver the fruits. Note that we are not passing anything,
    #   # `deliver_fruits` knows that we loaded something.
    #   grocer.deliver_fruits
    #
    #   # Load some vegetables and deliver them to Airbrake. Note that the
    #   # fruits have been delivered and therefore the grocer doesn't have them
    #   # anymore. We merge veggies with the new context.
    #   grocer.load_veggies(%w(cabbage carrot onion))
    #   grocer.deliver_veggies
    #
    #   # The context is empty again, feel free to load more.
    #
    # @param [Hash{Symbol=>Object}] context
    # @return [void]
    def merge_context(context)
      @notifiers[:default].merge_context(context)
    end
  end
end
