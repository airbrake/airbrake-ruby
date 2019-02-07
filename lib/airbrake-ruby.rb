require 'net/https'
require 'logger'
require 'json'
require 'thread'
require 'set'
require 'socket'
require 'time'

require 'airbrake-ruby/version'
require 'airbrake-ruby/config'
require 'airbrake-ruby/config/validator'
require 'airbrake-ruby/promise'
require 'airbrake-ruby/sync_sender'
require 'airbrake-ruby/async_sender'
require 'airbrake-ruby/response'
require 'airbrake-ruby/nested_exception'
require 'airbrake-ruby/ignorable'
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
require 'airbrake-ruby/filters/git_repository_filter'
require 'airbrake-ruby/filters/git_last_checkout_filter'
require 'airbrake-ruby/filters/sql_filter'
require 'airbrake-ruby/filter_chain'
require 'airbrake-ruby/code_hunk'
require 'airbrake-ruby/file_cache'
require 'airbrake-ruby/tdigest_big_endianness'
require 'airbrake-ruby/hash_keyable'
require 'airbrake-ruby/performance_notifier'
require 'airbrake-ruby/notice_notifier'
require 'airbrake-ruby/deploy_notifier'
require 'airbrake-ruby/stat'
require 'airbrake-ruby/time_truncate'

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
# @see Airbrake::NoticeNotifier
# @since v1.0.0
module Airbrake
  # The general error that this library uses when it wants to raise.
  Error = Class.new(StandardError)

  # @return [String] the label to be prepended to the log output
  LOG_LABEL = '**Airbrake:'.freeze

  # @return [Boolean] true if current Ruby is JRuby. The result is used for
  #  special cases where we need to work around older implementations
  JRUBY = (RUBY_ENGINE == 'jruby')

  # @!macro see_public_api_method
  #   @see Airbrake.$0

  # NilNoticeNotifier is a no-op notice notifier, which mimics
  # +Airbrake::NoticeNotifier+ and serves only the purpose of making the library
  # API easier to use.
  #
  # @since v2.1.0
  class NilNoticeNotifier
    # @macro see_public_api_method
    def notify(_exception, _params = {}, &block); end

    # @macro see_public_api_method
    def notify_sync(_exception, _params = {}, &block); end

    # @macro see_public_api_method
    def add_filter(_filter = nil, &_block); end

    # @macro see_public_api_method
    def delete_filter(_filter_class); end

    # @macro see_public_api_method
    def build_notice(_exception, _params = {}); end

    # @macro see_public_api_method
    def close; end

    # @macro see_public_api_method
    def configured?
      false
    end

    # @macro see_public_api_method
    def merge_context(_context); end
  end

  # @deprecated Use {Airbrake::NoticeNotifier} instead
  Notifier = NoticeNotifier
  deprecate_constant(:Notifier) if respond_to?(:deprecate_constant)

  # @deprecated Use {Airbrake::NilNoticeNotifier} instead
  NilNotifier = NilNoticeNotifier
  deprecate_constant(:NilNotifier) if respond_to?(:deprecate_constant)

  # NilPerformanceNotifier is a no-op notifier, which mimics
  # {Airbrake::PerformanceNotifier} and serves only the purpose of making the
  # library API easier to use.
  #
  # @since v3.2.0
  class NilPerformanceNotifier
    # @see Airbrake.notify_request
    # @see Airbrake.notify_query
    def notify(_performance_info); end

    # @see Airbrake.notify_request
    # @see Airbrake.notify_query
    def add_filter(_filter = nil, &_block); end

    # @see Airbrake.notify_request
    # @see Airbrake.notify_query
    def delete_filter(_filter_class); end
  end

  # NilDeployNotifier is a no-op notifier, which mimics
  # {Airbrake::DeployNotifier} and serves only the purpose of making the library
  # API easier to use.
  #
  # @since v3.1.0
  class NilDeployNotifier
    # @see Airbrake.create_deploy
    def notify(_deploy_info); end
  end

  # A Hash that holds all notice notifiers. The keys of the Hash are notifier
  # names, the values are {Airbrake::NoticeNotifier} instances. If a notifier is
  # not assigned to the hash, then it returns a null object (NilNoticeNotifier).
  @notice_notifiers = Hash.new(NilNoticeNotifier.new)

  # A Hash that holds all performance notifiers. The keys of the Hash are
  # notifier names, the values are {Airbrake::PerformanceNotifier} instances. If
  # a notifier is not assigned to the hash, then it returns a null object
  # (NilPerformanceNotifier).
  @performance_notifiers = Hash.new(NilPerformanceNotifier.new)

  # A Hash that holds all deploy notifiers. The keys of the Hash are notifier
  # names, the values are {Airbrake::DeployNotifier} instances. If a deploy
  # notifier is not assigned to the hash, then it returns a null object
  # (NilDeployNotifier).
  @deploy_notifiers = Hash.new(NilDeployNotifier.new)

  class << self
    # Retrieves configured notifiers.
    #
    # @example
    #   Airbrake[:my_notifier].notify('oops')
    #
    # @param [Symbol] notifier_name the name of the notice notifier you want to
    #   use
    # @return [Airbrake::NoticeNotifier, NilClass]
    # @since v1.8.0
    def [](notifier_name)
      @notice_notifiers[notifier_name]
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
    # @raise [Airbrake::Error] when either +project_id+ or +project_key+
    #   is missing (or both)
    # @note There's no way to reconfigure a notifier
    # @note There's no way to read config values outside of this library
    def configure(notifier_name = :default)
      yield config = Airbrake::Config.new

      if @notice_notifiers.key?(notifier_name)
        raise Airbrake::Error,
              "the '#{notifier_name}' notifier was already configured"
      end

      raise Airbrake::Error, config.validation_error_message unless config.valid?

      @notice_notifiers[notifier_name] = NoticeNotifier.new(config)
      @performance_notifiers[notifier_name] = PerformanceNotifier.new(config)
      @deploy_notifiers[notifier_name] = DeployNotifier.new(config)
    end

    # @return [Boolean] true if the notifier was configured, false otherwise
    # @since v2.3.0
    def configured?
      @notice_notifiers[:default].configured?
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
      @notice_notifiers[:default].notify(exception, params, &block)
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
      @notice_notifiers[:default].notify_sync(exception, params, &block)
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
    def add_filter(filter = nil, &block)
      @notice_notifiers[:default].add_filter(filter, &block)
    end

    # Deletes a filter added via {Airbrake#add_filter}.
    #
    # @example
    #   # Add a MyFilter filter (we pass an instance here).
    #   Airbrake.add_filter(MyFilter.new)
    #
    #   # Delete the filter (we pass class name here).
    #   Airbrake.delete_filter(MyFilter)
    #
    # @param [Class] filter_class The class of the filter you want to delete
    # @return [void]
    # @since v3.1.0
    # @note This method cannot delete filters assigned via the Proc form.
    def delete_filter(filter_class)
      @notice_notifiers[:default].delete_filter(filter_class)
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
      @notice_notifiers[:default].build_notice(exception, params)
    end

    # Makes the notice notifier a no-op, which means you cannot use the
    # {.notify} and {.notify_sync} methods anymore. It also stops the notice
    # notifier's worker threads.
    #
    # @example
    #   Airbrake.close
    #   Airbrake.notify('App crashed!') #=> raises Airbrake::Error
    #
    # @return [void]
    def close
      @notice_notifiers[:default].close
    end

    # Pings the Airbrake Deploy API endpoint about the occurred deploy. This
    # method is used by the airbrake gem for various integrations.
    #
    # @param [Hash{Symbol=>String}] deploy_info The params for the API
    # @option deploy_info [Symbol] :environment
    # @option deploy_info [Symbol] :username
    # @option deploy_info [Symbol] :repository
    # @option deploy_info [Symbol] :revision
    # @option deploy_info [Symbol] :version
    # @return [void]
    def create_deploy(deploy_info)
      @deploy_notifiers[:default].notify(deploy_info)
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
      @notice_notifiers[:default].merge_context(context)
    end

    # Increments request statistics of a certain +route+ that was invoked on
    # +start_time+ and ended on +end_time+ with +method+, and returned
    # +status_code+.
    #
    # After a certain amount of time (n seconds) the aggregated route
    # information will be sent to Airbrake.
    #
    # @example
    #   Airbrake.notify_request(
    #     method: 'POST',
    #     route: '/thing/:id/create',
    #     status_code: 200,
    #     start_time: timestamp,
    #     end_time: Time.now
    #   )
    #
    # @param [Hash{Symbol=>Object}] request_info
    # @option request_info [String] :method The HTTP method that was invoked
    # @option request_info [String] :route The route that was invoked
    # @option request_info [Integer] :status_code The respose code that the route returned
    # @option request_info [Date] :start_time When the request started
    # @option request_info [Time] :end_time When the request ended (optional)
    # @return [void]
    # @since v3.0.0
    # @see Airbrake::PerformanceNotifier#notify
    def notify_request(request_info)
      @performance_notifiers[:default].notify(Request.new(request_info))
    end

    # Increments SQL statistics of a certain +query+ that was invoked on
    # +start_time+ and finished on +end_time+. When +method+ and +route+ are
    # provided, the query is grouped by these parameters.
    #
    # After a certain amount of time (n seconds) the aggregated query
    # information will be sent to Airbrake.
    #
    # @example
    #   Airbrake.notify_query(
    #     method: 'GET',
    #     route: '/things',
    #     query: 'SELECT * FROM things',
    #     start_time: timestamp,
    #     end_time: Time.now
    #   )
    #
    # @param [Hash{Symbol=>Object}] query_info
    # @option request_info [String] :method The HTTP method that triggered this
    #   SQL query (optional)
    # @option request_info [String] :route The route that triggered this SQL
    #    query (optional)
    # @option request_info [String] :query The query that was executed
    # @option request_info [Date] :start_time When the query started executing
    # @option request_info [Time] :end_time When the query finished (optional)
    # @return [void]
    # @since v3.2.0
    # @see Airbrake::PerformanceNotifier#notify
    def notify_query(query_info)
      @performance_notifiers[:default].notify(Query.new(query_info))
    end

    # Runs a callback before {.notify_request} or {.notify_query} kicks in. This
    # is useful if you want to ignore specific resources or filter the data the
    # resource contains.
    #
    # @example Ignore all resources
    #   Airbrake.add_performance_filter(&:ignore!)
    # @example Filter sensitive data
    #   Airbrake.add_performance_filter do |resource|
    #     case resource
    #     when Airbrake::Query
    #       resource.route = '[Filtered]'
    #     when Airbrake::Request
    #       resource.query = '[Filtered]'
    #     end
    #   end
    # @example Filter with help of a class
    #   class MyFilter
    #     def call(resource)
    #       # ...
    #     end
    #   end
    #
    #   Airbrake.add_performance_filter(MyFilter.new)
    #
    # @param [#call] filter The filter object
    # @yield [resource] The resource to filter
    # @yieldparam [Airbrake::Query, Airbrake::Request]
    # @yieldreturn [void]
    # @return [void]
    # @since v3.2.0
    # @see Airbrake::PerformanceNotifier#add_filter
    def add_performance_filter(filter = nil, &block)
      @performance_notifiers[:default].add_filter(filter, &block)
    end

    # Deletes a filter added via {Airbrake#add_performance_filter}.
    #
    # @example
    #   # Add a MyFilter filter (we pass an instance here).
    #   Airbrake.add_performance_filter(MyFilter.new)
    #
    #   # Delete the filter (we pass class name here).
    #   Airbrake.delete_performance_filter(MyFilter)
    #
    # @param [Class] filter_class The class of the filter you want to delete
    # @return [void]
    # @since v3.2.0
    # @note This method cannot delete filters assigned via the Proc form.
    # @see Airbrake::PerformanceNotifier#delete_filter
    def delete_performance_filter(filter_class)
      @performance_notifiers[:default].delete_filter(filter_class)
    end
  end
end
