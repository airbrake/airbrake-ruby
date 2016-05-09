require 'net/https'
require 'logger'
require 'json'
require 'thread'
require 'set'
require 'socket'

require 'airbrake-ruby/version'
require 'airbrake-ruby/config'
require 'airbrake-ruby/sync_sender'
require 'airbrake-ruby/async_sender'
require 'airbrake-ruby/response'
require 'airbrake-ruby/nested_exception'
require 'airbrake-ruby/notice'
require 'airbrake-ruby/backtrace'
require 'airbrake-ruby/filter_chain'
require 'airbrake-ruby/payload_truncator'
require 'airbrake-ruby/filters'
require 'airbrake-ruby/filters/keys_filter'
require 'airbrake-ruby/filters/keys_whitelist'
require 'airbrake-ruby/filters/keys_blacklist'
require 'airbrake-ruby/notifier'

##
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
#   Airbrake.notify('Oops', params, :my_other_project)
#
# @see Airbrake::Notifier
module Airbrake
  ##
  # The general error that this library uses when it wants to raise.
  Error = Class.new(StandardError)

  ##
  # @return [String] the label to be prepended to the log output
  LOG_LABEL = '**Airbrake:'.freeze

  ##
  # A Hash that holds all notifiers. The keys of the Hash are notifier
  # names, the values are Airbrake::Notifier instances.
  @notifiers = {}

  class << self
    ##
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
    # @param [Symbol] notifier the name to be associated with the notifier
    # @yield [config] The configuration object
    # @yieldparam config [Airbrake::Config]
    # @return [void]
    # @raise [Airbrake::Error] when trying to reconfigure already
    #   existing notifier
    # @note There's no way to reconfigure a notifier
    # @note There's no way to read config values outside of this library
    def configure(notifier = :default)
      yield config = Airbrake::Config.new

      if configured?(notifier)
        raise Airbrake::Error,
              "the '#{notifier}' notifier was already configured"
      else
        @notifiers[notifier] = Notifier.new(config)
      end
    end

    # @!macro proxy_method
    #   @param [Symbol] notifier The name of the notifier
    #   @raise [Airbrake::Error] if +notifier+ doesn't exist
    #   @see Airbrake::Notifier#$0

    ##
    # Sends an exception to Airbrake asynchronously.
    #
    # @macro proxy_method
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
    # @return [nil]
    # @see .notify_sync
    def notify(exception, params = {}, notifier = :default)
      call_notifier(notifier, __method__, exception, params)
    end

    ##
    # Sends an exception to Airbrake synchronously.
    #
    # @macro proxy_method
    # @example
    #   Airbrake.notify_sync('App crashed!')
    #   #=> {"id"=>"123", "url"=>"https://airbrake.io/locate/321"}
    #
    # @return [Hash{String=>String}] the reponse from the server
    # @see .notify
    # @since v5.0.0
    def notify_sync(exception, params = {}, notifier = :default)
      call_notifier(notifier, __method__, exception, params)
    end

    ##
    # Runs a callback before {.notify} or {.notify_sync} kicks in. This is
    # useful if you want to ignore specific notices or filter the data the
    # notice contains.
    #
    # @macro proxy_method
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
    # @since v5.0.0
    # @note Once a filter was added, there's no way to delete it
    def add_filter(filter = nil, notifier = :default, &block)
      call_notifier(notifier, __method__, filter, &block)
    end

    ##
    # Specifies which keys should *not* be filtered. All other keys will be
    # substituted with the +[Filtered]+ label.
    #
    # @macro proxy_method
    # @example
    #   Airbrake.whitelist([:email, /user/i, 'account_id'])
    #
    # @param [Array<String, Symbol, Regexp>] keys The keys, which shouldn't be
    #   filtered
    # @return [void]
    # @since v5.0.0
    # @see .blacklist_keys
    # @deprecated Please use {Airbrake::Config#whitelist_keys} instead
    def whitelist_keys(keys, notifier = :default)
      call_notifier(notifier, __method__, keys)
    end

    ##
    # Specifies which keys *should* be filtered. Such keys will be replaced with
    # the +[Filtered]+ label.
    #
    # @macro proxy_method
    # @example
    #   Airbrake.blacklist_keys([:email, /credit/i, 'password'])
    #
    # @param [Array<String, Symbol, Regexp>] keys The keys, which should be
    #   filtered
    # @return [void]
    # @since v5.0.0
    # @see .whitelist_keys
    # @deprecated Please use {Airbrake::Config#blacklist_keys} instead
    def blacklist_keys(keys, notifier = :default)
      call_notifier(notifier, __method__, keys)
    end

    ##
    # Builds an Airbrake notice. This is useful, if you want to add or modify a
    # value only for a specific notice. When you're done modifying the notice,
    # send it with {.notify} or {.notify_sync}.
    #
    # @macro proxy_method
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
    # @since v5.0.0
    def build_notice(exception, params = {}, notifier = :default)
      call_notifier(notifier, __method__, exception, params)
    end

    ##
    # Makes the notifier a no-op, which means you cannot use the {.notify} and
    # {.notify_sync} methods anymore. It also stops the notifier's worker
    # threads.
    #
    # @macro proxy_method
    # @example
    #   Airbrake.close
    #   Airbrake.notify('App crashed!') #=> raises Airbrake::Error
    #
    # @return [void]
    # @since v5.0.0
    def close(notifier = :default)
      call_notifier(notifier, __method__)
    end

    ##
    # Pings the Airbrake Deploy API endpoint about the occurred deploy. This
    # method is used by the airbrake gem for various integrations.
    #
    # @macro proxy_method
    # @param [Hash{Symbol=>String}] deploy_params The params for the API
    # @option deploy_params [Symbol] :environment
    # @option deploy_params [Symbol] :username
    # @option deploy_params [Symbol] :repository
    # @option deploy_params [Symbol] :revision
    # @option deploy_params [Symbol] :version
    # @return [void]
    # @since v5.0.0
    # @api private
    def create_deploy(deploy_params, notifier = :default)
      call_notifier(notifier, __method__, deploy_params)
    end

    private

    ##
    # Calls +method+ on +notifier+ with provided +args+. If +notifier+ is not
    # configured, returns nil.
    def call_notifier(notifier, method, *args, &block)
      return unless configured?(notifier)
      @notifiers[notifier].__send__(method, *args, &block)
    end

    def configured?(notifier)
      @notifiers.key?(notifier)
    end
  end
end
