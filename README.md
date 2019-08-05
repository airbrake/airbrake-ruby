Airbrake Ruby
=============

[![Circle Build Status](https://circleci.com/gh/airbrake/airbrake-ruby.svg?style=shield)](https://circleci.com/gh/airbrake/airbrake-ruby)
[![Code Climate](https://codeclimate.com/github/airbrake/airbrake-ruby.svg)](https://codeclimate.com/github/airbrake/airbrake-ruby)
[![Gem Version](https://badge.fury.io/rb/airbrake-ruby.svg)](http://badge.fury.io/rb/airbrake-ruby)
[![Documentation Status](http://inch-ci.org/github/airbrake/airbrake-ruby.svg?branch=master)](http://inch-ci.org/github/airbrake/airbrake-ruby)
[![Downloads](https://img.shields.io/gem/dt/airbrake-ruby.svg?style=flat)](https://rubygems.org/gems/airbrake-ruby)

![Airbrake Ruby][arthur-ruby]

* [Airbrake README][airbrake-gem]
* [Airbrake Ruby README](https://github.com/airbrake/airbrake-ruby)
* [YARD API documentation][yard-api]

Introduction
------------

_Airbrake Ruby_ is a plain Ruby notifier for [Airbrake][airbrake.io], the
leading exception reporting service. Airbrake Ruby provides minimalist API that
enables the ability to send _any_ Ruby exception to the Airbrake dashboard. The
library is extremely lightweight and it perfectly suits plain Ruby applications.
For apps that are built with _Rails_, _Sinatra_ or any other Rack-compliant web
framework we offer the [`airbrake`][airbrake-gem] gem.  It has additional
features such as _reporting of any unhandled exceptions automatically_,
integrations with Resque, Sidekiq, Delayed Job and many more.

Key features
------------

* Simple, consistent and easy-to-use library API<sup>[[link](#api)]</sup>
* Awesome performance (check out our benchmarks)<sup>[[link](#running-benchmarks)]</sup>
* Asynchronous exception reporting<sup>[[link](#asynchronous-airbrake-options)]</sup>
* Promise support<sup>[[link](#promise)]</sup>
* Flexible configuration options<sup>[[link](#configuration)]</sup>
* Support for proxying<sup>[[link](#proxy)]</sup>
* Support for environments<sup>[[link](#environment)]</sup>
* Filters support (filter out sensitive or unwanted data that shouldn't be sent)<sup>[[link](#airbrakeadd_filter)]</sup>
* Ability to ignore exceptions based on their class, backtrace or any other
  condition<sup>[[link](#airbrakeadd_filter)]</sup>
* Support for Java exceptions occurring in JRuby
* SSL support (all communication with Airbrake is encrypted by default)
* Support for fatal exceptions (the ones that terminate your program)
* Support for custom exception attributes<sup>[[link](#custom-exception-attributes)]</sup>
* Severity support<sup>[[link](#setting-severity)]</sup>
* Support for code hunks (lines of code surrounding each backtrace frame)<sup>[[link](#code_hunks)]</sup>
* Ability to add context to reported exceptions<sup>[[link](#airbrakemerge_context)]</sup>
* Dependency tracking<sup>[[link](#airbrakefiltersdependencyfilter)]</sup>
* Automatic and manual deploy tracking <sup>[[link](#airbrakenotify_deploy)]</sup>
* Performance monitoring for web applications (route statistics, SQL queries) <sup>[[link](#performance_stats)]</sup>
* Last but not least, we follow semantic versioning 2.0.0<sup>[[link][semver2]]</sup>

Installation
------------

### Bundler

Add the Airbrake Ruby gem to your Gemfile:

```ruby
gem 'airbrake-ruby', '~> 4.5'
```

### Manual

Invoke the following command from your terminal:

```ruby
gem install airbrake-ruby
```

Example
-------

This is the minimal example that you can use to test Airbrake Ruby with your
project.

```ruby
require 'airbrake-ruby'

# Every Airbrake notifier must configure
# two options: `project_id` and `project_key`.
Airbrake.configure do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

# Asynchronous error delivery.
begin
  1/0
rescue ZeroDivisionError => ex
  # Return value is always `nil`.
  Airbrake.notify(ex)
end

puts 'A ZeroDivisionError was sent to Airbrake asynchronously!',
     "Find it at your project's dashboard on https://airbrake.io"

# Synchronous error delivery.
begin
  1/0
rescue ZeroDivisionError => ex
  # Return value is a Hash.
  response = Airbrake.notify_sync(ex)
end

puts "\nAnother ZeroDivisionError was sent to Airbrake, but this time synchronously.",
     "See it at #{response['url']}"
```

Configuration
-------------

#### project_id & project_key

You **must** set both `project_id` & `project_key`.

To find your `project_id` and `project_key` navigate to your project's _General
Settings_ and copy the values from the right sidebar.

![][project-idkey]

```ruby
Airbrake.configure do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end
```

#### proxy

If your server is not able to directly reach Airbrake, you can use a built-in
proxy. By default, Airbrake Ruby uses a direct connection.

```ruby
Airbrake.configure do |c|
  c.proxy = {
    host: 'proxy.example.com',
    port: 4038,
    user: 'john-doe',
    password: 'p4ssw0rd'
  }
end
```

#### logger

By default, Airbrake Ruby outputs to `STDOUT`. The default logger level is
`Logger::WARN`. It's possible to add your custom logger.

```ruby
Airbrake.configure do |c|
  c.logger = Logger.new('log.txt')
end
```

#### app_version

The version of your application that you can pass to differentiate exceptions
between multiple versions. It's not set by default.

```ruby
Airbrake.configure do |c|
  c.app_version = '1.0.0'
end
```

#### versions

A hash of arbitrary versions that your application uses that you want to
track (Rails, Linux kernel, API version, etc.). By default, it's empty.

```ruby
Airbrake.configure do |c|
  c.versions = {
    'Rails' => '5.2.0',
    'bundler' => '1.16.1',
    'LinuxKernel' => '4.4.0-97-generic'
  }
end
```

#### host

By default, it is set to `airbrake.io`. A `host` is a web address containing a
scheme ("http" or "https"), a host and a port. You can omit the port (80 will be
assumed) and the scheme ("https" will be assumed).

```ruby
Airbrake.configure do |c|
  c.host = 'http://localhost:8080'
end
```

If your backend is hosted behind a subpath such as `http://localhost:8080/api`,
make sure to append a trailing slash to the end of the URL:

```ruby
Airbrake.configure do |c|
  c.host = 'http://localhost:8080/api/' # Note the trailing slash
end
```

#### root_directory

Configures the root directory of your project. Expects a String or a Pathname,
which represents the path to your project. Providing this option helps us to
filter out repetitive data from backtrace frames and link to GitHub files
from our dashboard.

```ruby
Airbrake.configure do |c|
  c.root_directory = '/var/www/project'
end
```

#### environment

Configures the environment the application is running in. Helps the Airbrake
dashboard to distinguish between exceptions occurring in different
environments. By default, it's not set.

```ruby
Airbrake.configure do |c|
  c.environment = :production
end
```

#### ignore_environments

Setting this option allows Airbrake to filter exceptions occurring in unwanted
environments such as `:test`. By default, it is equal to an empty Array, which
means Airbrake Ruby sends exceptions occurring in all environments.

This will also disable performance stat collection for matched environments.

```ruby
Airbrake.configure do |c|
  c.ignore_environments = [:production, /test.+/]
end
```

#### timeout

The number of seconds to wait for the connection to Airbrake to open.

```ruby
Airbrake.configure do |c|
  c.timeout = 10
end
```

#### blacklist_keys

Specifies which keys in the payload (parameters, session data, environment data,
etc) should be filtered. Before sending an error, filtered keys will be
substituted with the `[Filtered]` label.

It accepts Strings, Symbols & Regexps, which represent keys of values to be
filtered.

```ruby
Airbrake.configure do |c|
  c.blacklist_keys = [:email, /credit/i, 'password']
end

Airbrake.notify('App crashed!', {
  user: 'John',
  password: 's3kr3t',
  email: 'john@example.com',
  credit_card: '5555555555554444'
})

# The dashboard will display this parameter as filtered, but other values won't
# be affected:
#   { user: 'John',
#     password: '[Filtered]',
#     email: '[Filtered]',
#     credit_card: '[Filtered]' }
```

##### Using Procs to delay filters configuration

If you cannot inline your keys (for example, they should be loaded from external
process), there's a way to load them later. Let's imagine `Keyloader.load_keys`
builds an Array of keys by talking to another process:

```ruby
module Keyloader
  # Builds an Array of keys (talking to another process is omitted).
  def self.load_keys
    [:credit_card, :telephone]
  end
end
```

We need to wrap this call in a Proc, so the library can execute it later (it
gets executed on first notify, only once):

```ruby
Airbrake.configure do |c|
  # You can mix inline keys and Procs.
  c.blacklist_keys = [:email, proc { Keyloader.load_keys }, 'password']
end
```

The Proc *must* return an Array consisting only of the elements, which are
considered to be valid for this option.

#### whitelist_keys

Specifies which keys in the payload (parameters, session data, environment data,
etc) should _not_ be filtered. All other keys will be substituted with the
`[Filtered]` label.

It accepts Strings, Symbols & Regexps, which represent keys the values of which
shouldn't be filtered.

```ruby
Airbrake.configure do |c|
  c.whitelist_keys = [:email, /user/i, 'account_id']
end

Airbrake.notify(StandardError.new('App crashed!'), {
  user: 'John',
  password: 's3kr3t',
  email: 'john@example.com',
  account_id: 42
})

# The dashboard will display this parameter as is, but all other values will be
# filtered:
#   { user: 'John',
#     password: '[Filtered]',
#     email: 'john@example.com',
#     account_id: 42 }
```

##### Using Procs to delay filters configuration

See documentation about
[blacklisting using Proc objects](#using-procs-to-delay-filters-configuration).
It's identical.

#### code_hunks

Code hunks are lines of code surrounding each backtrace frame. When
`root_directory` is set to some value, code hunks are collected only for frames
inside that directory. If `root_directory` isn't configured, then first ten code
hunks are collected. By default, it's set to `true`.

```ruby
Airbrake.configure do |c|
  c.code_hunks = false
end
```

#### performance_stats

Configures [Airbrake Performance Monitoring][airbrake-performance-monitoring]
statistics collection aggregated per route. These are displayed on the
Performance tab of your project. By default, it's enabled.

The statistics is sent via:

* [`Airbrake.notify_request`](#airbrakenotify_request)

```ruby
Airbrake.configure do |c|
  c.performance_stats = true
end
```

#### query_stats

Configures [Airbrake Performance Monitoring][airbrake-performance-monitoring]
query collection. These are displayed on the Performance tab of your project. If
`performance_stats` is `false`, setting this to `true` won't have effect because
`performance_stats` has higher precedence. By default, it's disabled.
**WARNING**: this feature is currently in alpha and it's not available for all
accounts.

The statistics is sent via:

* [`Airbrake.notify_query`](#airbrakenotify_query)

```ruby
Airbrake.configure do |c|
  c.query_stats = false
end
```

### Asynchronous Airbrake options

The options listed below apply to [`Airbrake.notify`](#airbrakenotify), they do
not apply to [`Airbrake.notify_sync`](#airbrakenotify_sync).

#### queue_size

The size of the notice queue. The default value is 100. You can increase the
value according to your needs.

```ruby
Airbrake.configure do |c|
  c.queue_size = 200
end
```

#### workers

The number of threads that handle notice sending. The default value is 1.

```ruby
Airbrake.configure do |c|
  c.workers = 5
end
```

API
---

### Airbrake

#### Airbrake.notify

Sends an exception to Airbrake asynchronously.

```ruby
Airbrake.notify('App crashed!')
```

As the first parameter, accepts:

* an `Exception` (will be sent directly)
* any object that can be converted to String with `#to_s` (the information from
  the object will be used as the message of a `RuntimeException` that we build
  internally)
* an `Airbrake::Notice`

As the second parameter, accepts a hash with additional data. That data will be
displayed in the _Params_ tab in your project's dashboard.

```ruby
Airbrake.notify('App crashed!', {
  anything: 'you',
  wish: 'to add'
})
```

Accepts a block, which yields an `Airbrake::Notice`:

```ruby
Airbrake.notify('App crashed') do |notice|
  notice[:params][:foo] = :bar
end
```

Returns an [`Airbrake::Promise`](#promise), which can be used to read Airbrake
error ids.


##### Setting severity

[Severity][what-is-severity] allows categorizing how severe an error is. By
default, it's set to `error`. To redefine severity, simply overwrite
`context/severity` of a notice object. For example:

```ruby
Airbrake.notify do |notice|
  notice[:context][:severity] = 'critical'
end
```

#### Airbrake.notify_sync

Sends an exception to Airbrake synchronously. Returns a Hash with an error ID
and a URL to the error.

```ruby
Airbrake.notify_sync('App crashed!')
#=> {"id"=>"1516018011377823762", "url"=>"https://airbrake.io/locate/1516018011377823762"}
```

Accepts the same parameters as [`Airbrake.notify`](#airbrakenotify).

#### Airbrake.add_filter

Runs a callback before `.notify` kicks in. Yields an `Airbrake::Notice`. This is
useful if you want to ignore specific notices or filter the data the notice
contains.

If you want to ignore a notice, simply mark it with `Notice#ignore!`. This
interrupts the execution chain of the `add_filter` callbacks. Once you ignore
a notice, there's no way to unignore it.

This example demonstrates how to ignore **all** notices.

```ruby
Airbrake.add_filter(&:ignore!)
```

Instead, you can ignore notices based on some condition.

```ruby
Airbrake.add_filter do |notice|
  notice.ignore! if notice.stash[:exception].is_a?(StandardError)
end
```

In order to filter a notice, simply change the data you are interested in.

```ruby
Airbrake.add_filter do |notice|
  if notice[:params][:password]
    # Filter out password.
    notice[:params][:password] = '[Filtered]'
  end
end
```

Notices can carry custom objects attached to
the [notice stash](#noticestash--noticestash). Such notices can be produced
by [`build_notice`](#airbrakebuild_notice) manually or provided to you by an
Airbrake integration:

```ruby
# Build a notice and store a Request object in the stash.
notice = Airbrake.build_notice('oops')
notice.stash[:request] = Request.new

Airbrake.add_filter do |notice|
  # Access the stored request object inside a filter and interact with it.
  notice[:params][:remoteIp] = notice.stash[:request].env['REMOTE_IP']
end
```

#### Airbrake.delete_filter

Deletes a filter added via [`add_filter`](#airbrakeadd_filter). Expects a class name of the filter.

```ruby
# Add a MyFilter filter (we pass an instance here).
Airbrake.add_filter(MyFilter.new)

# Delete the filter (we pass class name here).
Airbrake.delete_filter(MyFilter)
```

Note: This method cannot delete filters assigned via the Proc form.

##### Optional filters

The library adds a few filters by default. However, some of them are optional
and not added. This is because such filters are overly specific and may not suit
every type of application, so there's no need to include them only to clutter
the notice object. You have to include such filters manually, if you think you
need them. The list of optional filters include:

###### Airbrake::Filters::ThreadFilter

Attaches thread & fiber local variables along with general thread information.

```ruby
Airbrake.add_filter(Airbrake::Filters::ThreadFilter.new)
```

###### Airbrake::Filters::DependencyFilter

Attaches loaded dependencies to the notice object (under
`context/versions/dependencies`).

```ruby
Airbrake.add_filter(Airbrake::Filters::DependencyFilter.new)
```

###### Airbrake::Filters::SqlFilter

Filters out sensitive data from queries that are sent via
[`Airbrake.notify_query`](#airbrakenotify_query). Sensitive data is everything
that is not table names or fields (e.g. column values and such).

Accepts a parameter, which signifies SQL dialect being used. Supported dialects:

* `:postgres`
* `:mysql`
* `:sqlite`
* `:cassandra`
* `:oracle`

```ruby
Airbrake.add_filter(Airbrake::Filters::SqlFilter.new(:postgres))
```

##### Using classes for building filters

For more complex filters you can use the special API. Simply pass an object that
responds to the `#call` method.

```ruby
class MyFilter
  def call(notice)
    # ...
  end
end

Airbrake.add_filter(MyFilter.new)
```

The library provides two default filters that you can use to filter notices:
[KeysBlacklist][keysblacklist] & [KeysWhitelist][keyswhitelist].

#### Airbrake.build_notice

Builds an [Airbrake notice][notice-v3]. This is useful, if you want to add or
modify a value only for a specific notice. When you're done modifying the
notice, send it with `Airbrake.notify` or `Airbrake.notify_sync`.

```ruby
notice = Airbrake.build_notice('App crashed!')
notice[:params][:username] = user.name
airbrake.notify_sync(notice)
```

See the block form of [`Airbrake.notify`](#airbrakenotify) for shorter syntax.

#### Airbrake.close

Makes the notifier a no-op, which means you cannot use the `.notify` and
`.notify_sync` methods anymore. It also stops the notifier's worker threads.

```ruby
Airbrake.close
Airbrake.notify('App crashed!') #=> raises Airbrake::Error
```

If you want to guarantee delivery of all unsent exceptions on program exit, make
sure to `close` your Airbrake notifier. Usually, this can be done with help of
Ruby's `at_exit` hook.

```ruby
at_exit do
  # Closes the default notifier.
  Airbrake.close
end
```

#### Airbrake.notify_deploy

Notifies Airbrake of a new deploy. Accepts a Hash with the following params:

```ruby
Airbrake.notify_deploy(
  environment: 'development',
  username: 'john',
  repository: 'https://github.com/airbrake/airbrake-ruby',
  revision: '0b77f289166c9fef4670588471b6584fbc34b0f3',
  version: '1.2.3'
)
```

#### Airbrake.configured?

Checks whether the notifier is configured or not:

```ruby
Airbrake.configured? #=> false
```

#### Airbrake.merge_context

Merges the provided context Hash with the notifier context. Upon a
[`notify/notify_sync`](#airbrakenotify) call the notifier context is attached to
the notice object under the `params/airbrake_context` key.

After the error is attached, the notifier context is cleared, allowing other
`notify` calls to start with a clean slate.

This method is specifically useful when you want to attach variables from
different scopes during the execution of your program and then send them to
Airbrake on error.

```ruby
class MerryGrocer
  def load_fruits(fruits)
    Airbrake.merge_context(fruits: fruits)
  end

  def deliver_fruits
    Airbrake.notify('fruitception')
  end

  def load_veggies(veggies)
    Airbrake.merge_context(veggies: veggies)
  end

  def deliver_veggies
    Airbrake.notify('veggieboom!')
  end
end

grocer = MerryGrocer.new

# The context is added to `notice[:params][:airbrake_context]`.
Airbrake.add_filter do |notice|
  puts "Context: #{notice[:params][:airbrake_context] || 'empty'}"
end

# Load some fruits to the context.
grocer.load_fruits(%w(mango banana apple))

# Deliver the fruits. Note that we are not passing anything, `deliver_fruits`
# knows that we loaded something.
grocer.deliver_fruits
#=> Context: ['mango', 'banana', 'apple']

# Load some vegetables and deliver them to Airbrake. Note that the fruits have
# been delivered and therefore the grocer doesn't have them anymore. We merge
# veggies with the new context.
grocer.load_veggies(%w(cabbage carrot onion))
grocer.deliver_veggies
#=> Context: ['cabbage', 'carrot', 'onion']

# The context is empty again, feel free to load more.
grocer.deliver_veggies
#=> Context: empty
```

#### Airbrake.notify_request

Sends performance statistics to [Airbrake Performance
Monitoring][airbrake-performance-monitoring]. The performance statistics are
displayed on the Performance tab of your project.

```ruby
Airbrake.notify_request(
  method: 'GET',
  route: '/things/1',
  status_code: 200,
  start_time: Time.new - 200,
  end_time: Time.new
)
```


Optionally, you can attach information to the stash (`request_id` in this
example).

```ruby
Airbrake.notify_request(
  {
    # normal params
  },
  request_id: 123
)
```

This stash can be accessed from performance filters as
`resource.stash[:request_id]`.

##### Return value

When [`config.performance_stats = false`](#performance_stats), it always returns
a rejected promise.

When [`config.performance_stats = true`](#performance_stats), then it aggregates
statistics and sends as a batch every 15 seconds.

#### Airbrake.notify_query

Sends SQL performance statistics to Airbrake. The performance statistics is
displayed on the Performance tab of your project.

```ruby
Airbrake.notify_query(
  method: 'GET',
  route: '/things/1',
  query: 'SELECT * FROM foos',
  func: 'foo', # optional
  file: 'foo.rb', # optional
  line: 123, # optional
  start_time: Time.new - 200,
  end_time: Time.new # optional
)
```

Optionally, you can attach information to the stash (`request_id` in this
example).

```ruby
Airbrake.notify_query(
  {
    # normal params
  },
  request_id: 123
)
```

This stash can be accessed from performance filters as
`resource.stash[:request_id]`.

##### Return value

When [`config.performance_stats = false`](#performance_stats), it always returns
a rejected promise.

When [`config.performance_stats = true`](#performance_stats), then it aggregates
statistics and sends as a batch every 15 seconds.

#### Airbrake.notify_performance_breakdown

Sends performance breakdown statistics by groups to Airbrake. The groups are
arbitrary (database, views, HTTP calls, etc.), but there can be only up to 10
groups per route in total.

```ruby
Airbrake.notify_performance_breakdown(
  method: 'GET',
  route: '/things/1',
  response_type: 'json',
  groups: { db: 24.0, view: 0.4 }, # ms
  start_time: Time.new
)
```

Optionally, you can attach information to the stash (`request_id` in this
example).

```ruby
Airbrake.notify_performance_breakdown(
  {
    # normal params
  },
  request_id: 123
)
```

This stash can be accessed from performance filters as
`resource.stash[:request_id]`.

##### Return value

When [`config.performance_stats = false`](#performance_stats), it always returns
a rejected promise.

When [`config.performance_stats = true`](#performance_stats), then it aggregates
statistics and sends as a batch every 15 seconds.

#### Airbrake.add_performance_filter

Adds a performance filter that filters performance data. Works exactly like
[`Airbrake.add_filter`](#airbrakeadd_filter). The only difference is that
instead of `Airbrake::Notice` it yields performance data (such as
`Airbrake::Query` or `Airbrake::Request`). It's invoked after
[`notify_request`](#airbrakenotify_request) or
[`notify_query`](#airbrakenotify_query) (but [`notify`](#airbrakenotify) calls
don't trigger it!).

```ruby
Airbrake.add_performance_filter do |resource|
  resource.ignore! if resource.route == %r{/health_check}
end
```

#### Airbrake.delete_performance_filter

Deletes a performance filter added via
[`Airbrake.add_performance_filter`](#airbrakeadd_performance_filter). Works
exactly like [`Airbrake.delete_filter`](#airbrakedelete_filter).

### Notice

#### Notice#ignore!

Ignores a notice. Ignored notices never reach the Airbrake dashboard. This is
useful in conjunction with `Airbrake.add_filter`.

```ruby
notice.ignore!
```

#### Notice#ignored?

Checks whether the notice was ignored.

```ruby
notice.ignored? #=> false
```

#### Notice#[] & Notice#[]=

Accesses a notice's payload, which can be read or filtered. Payload includes:

* `:errors`
* `:context`
* `:environment`
* `:session`
* `:params`

```ruby
notice[:params][:my_param] = 'foobar'
```

#### Notice#stash[] & Notice#stash[]=

Each notice can carry arbitrary objects stored in the notice stash, accessible
through the `stash` method. Callbacks defined
via [`add_filter`](#airbrakeadd_filter) can access the stash and attach stored
object's values to the notice payload:

```ruby
notice.stash[:my_object] = Object.new

Airbrake.add_filter do |notice|
  # Access :my_object from the stash and directly call its method. The return
  # value will be sent to Airbrake.
  notice[:params][:object_id] = notice.stash[:my_object].object_id
end
```

### Promise

`Airbrake::Promise` represents a simplified promise object (similar to promises
found in JavaScript), which allows chaining callbacks that are executed when
the promise is either resolved or rejected.

#### Promise#then

Attaches a callback to be executed when a promise is resolved (fulfilled). The
promise is resolved whenever the Airbrake API successfully accepts your
exception.

Yields successful response containing the id of an error at Airbrake and URL to
the error at Airbrake.  Returns `self`.

```rb
Airbrake.notify('Oops').then { |response| puts response }
#=> {"id"=>"00054415-8201-e9c6-65d6-fc4d231d2871",
#    "url"=>"http://localhost/locate/00054415-8201-e9c6-65d6-fc4d231d2871"}
```

#### Promise#rescue

Attaches a callback to be executed when a promise is rejected. The promise is
rejected whenever the API returns an error response.

Yields an error message in the form of String explaining the failure and returns
`self`.

```rb
Airbrake.notify('Oops').rescue { |error| puts error }
#=> Failed to open TCP connection to localhostt:80
```

### Custom exception attributes

The library supports custom exception attributes. This is useful if you work
with custom exceptions, which define non-standard attributes and you can't
attach any additional data with help of the [`add_filter`](#airbrakeadd_filter)
API due to the fact that the data isn't available at configuration time yet.

In this case, you could define a special hook method on your exception called
`#to_airbrake`. The method must return a Hash the keys of which must be a subset
of the ones mentioned in the [`Notice#[]`](#notice--notice) API.

```ruby
class MyException
  def initialize
    @http_code = 404
  end

  # The library expects you to define this method. You must return a Hash,
  # containing the keys you want to modify.
  def to_airbrake
    { params: { http_code: @http_code } }
  end
end

# The `{ http_code: 404 }` Hash will transported to the Airbrake dashboard via
# the `#to_airbrake` method.
Airbrake.notify(MyException.new)
```

Note: you don't have to call `Airbrake.notify` manually to be able to benefit
from this API. It should "just work".

### Benchmark

#### .measure

Measures [monotonic time][monotonic] for the given operation. Returns elapsed
time in milliseconds.

```ruby
time = Airbrake::Benchmark.measure do
  (1..10_000).inject(:*)
end

puts "Time: #{time}"
#=> Time: 67.40199995040894
```

### TimedTrace

Represents a chunk of code performance of which was measured and stored under a
label. The chunk is called a "span". Such spans can be used for [performance
breakdown](#notify_performance_breakdown) reporting.

#### .span

```ruby
# Measure time for a span called 'operation'.
timed_trace = Airbrake::TimedTrace.span('operation') do
  call_something
end
timed_trace.spans #=> { 'operation' => 0.123 }

# Send the spans to the Airbrake dashboard.
Airbrake.notify_performance_breakdown(
  method: 'GET',
  route: '/things/1',
  response_type: 'json',
  groups: timed_trace.spans
)
```

See [full documentation][yard-api] for more examples.

Additional notes
----------------

### Exception limit

The maximum size of an exception is 64KB. Exceptions that exceed this limit
will be truncated to fit the size.

### Running benchmarks

To run benchmarks related to asynchronous delivery, make sure to start a web
server on port 8080. We provide a simple server, which can be started with this
command (you need to have the [Go][golang] programming language installed):

```shell
go run benchmarks/server.go
```

In order to run benchmarks against `master`, add the `lib` directory to your
`LOAD_PATH` and choose the benchmark you are interested in:

```shell
ruby -Ilib benchmarks/notify_async_vs_sync.rb
```

### Reporting critical exceptions

Critical exceptions are unhandled exceptions that terminate your program. By
default, the library doesn't report them. However, you can either depend on the
[airbrake gem][airbrake-gem] instead, which supports them, or you can add
the following code somewhere in your app:

```ruby
at_exit do
  Airbrake.notify_sync($!) if $!
end
```

Supported Rubies
----------------

* CRuby >= 2.1.0
* JRuby >= 9k
* Rubinius >= 2.2.10

Contact
-------

In case you have a problem, question or a bug report, feel free to:

* [file an issue][issues]
* [send us an email](mailto:support@airbrake.io)
* [tweet at us][twitter]
* chat with us (visit [airbrake.io][airbrake.io] and click on the round orange
  button in the bottom right corner)

License
-------

The project uses the MIT License. See LICENSE.md for details.

[airbrake.io]: https://airbrake.io
[airbrake-gem]: https://github.com/airbrake/airbrake
[semver2]: http://semver.org/spec/v2.0.0.html
[project-idkey]: https://s3.amazonaws.com/airbrake-github-assets/airbrake-ruby/project-id-key.png
[issues]: https://github.com/airbrake/airbrake-ruby/issues
[twitter]: https://twitter.com/airbrake
[keysblacklist]: https://github.com/airbrake/airbrake-ruby/blob/master/lib/airbrake-ruby/filters/keys_blacklist.rb
[keyswhitelist]: https://github.com/airbrake/airbrake-ruby/blob/master/lib/airbrake-ruby/filters/keys_whitelist.rb
[golang]: https://golang.org/
[yard-api]: http://www.rubydoc.info/gems/airbrake-ruby
[arthur-ruby]: https://s3.amazonaws.com/airbrake-github-assets/airbrake-ruby/arthur-ruby.jpg
[what-is-severity]: https://airbrake.io/docs/airbrake-faq/what-is-severity/
[monotonic]: http://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_getres.html
[airbrake-performance-monitoring]: https://airbrake.io/product/performance
