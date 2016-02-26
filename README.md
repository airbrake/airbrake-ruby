Airbrake Ruby
=============

[![Build Status](https://circleci.com/gh/airbrake/airbrake-ruby.svg?style=shield)](https://circleci.com/gh/airbrake/airbrake-ruby)
[![semver]](http://semver.org)
[![Documentation Status](http://inch-ci.org/github/airbrake/airbrake-ruby.svg?branch=master)](http://inch-ci.org/github/airbrake/airbrake-ruby)
[![Issue Stats](http://issuestats.com/github/airbrake/airbrake-ruby/badge/pr?style=flat)](http://issuestats.com/github/airbrake/airbrake-ruby)
[![Issue Stats](http://issuestats.com/github/airbrake/airbrake-ruby/badge/issue?style=flat)](http://issuestats.com/github/airbrake/airbrake-ruby)

![Airbrake Ruby][arthur-ruby]

* [Airbrake README][airbrake-gem]
* [Airbrake Ruby README](https://github.com/airbrake/airbrake-ruby)
* [YARD API documentation][yard-api]

Introduction
------------

_Airbrake Ruby_ is a plain Ruby notifier for [Airbrake][airbrake.io], the
leading exception reporting service. Airbrake Ruby provides minimalist API that
enables the ability to send _any_ Ruby exception to the Airbrake dashboard. The
library is extremely lightweight, contains _no_ dependencies and perfectly suits
plain Ruby applications. For apps that are built with _Rails_, _Sinatra_ or any
other Rack-compliant web framework we offer the [`airbrake`][airbrake-gem] gem.
It has additional features such as _reporting of any unhandled exceptions
automatically_, integrations with Resque, Sidekiq, Delayed Job and many more.

Key features
------------

* Uses the new Airbrake JSON API (v3)<sup>[[link][notice-v3]]</sup>
* Simple, consistent and easy-to-use library API<sup>[[link](#api)]</sup>
* Awesome performance (check out our benchmarks)<sup>[[link](#running-benchmarks)]</sup>
* Asynchronous exception reporting<sup>[[link](#asynchronous-airbrake-options)]</sup>
* Flexible logging support (configure your own logger)<sup>[[link](#logger)]</sup>
* Flexible configuration options (configure as many Airbrake notifers in one
  application as you want)<sup>[[link](#configuration)]</sup>
* Support for proxying<sup>[[link](#proxy)]</sup>
* Support for environments<sup>[[link](#environment)]</sup>
* Filters support (filter out sensitive or unwanted data that shouldn't be sent)<sup>[[link](#airbrakeadd_filter)]</sup>
* Ability to ignore exceptions based on their class, backtrace or any other
  condition<sup>[[link](#airbrakeadd_filter)]</sup>
* Support for Java exceptions occurring in JRuby
* SSL support (all communication with Airbrake is encrypted by default)
* Support for fatal exceptions (the ones that terminate your program)
* Last but not least, we follow semantic versioning 2.0.0<sup>[[link][semver2]]</sup>

Installation
------------

### Bundler

Add the Airbrake Ruby gem to your Gemfile:

```ruby
gem 'airbrake-ruby', '~> 1.1'
```

### Manual

Invoke the following command from your terminal:

```ruby
gem install airbrake-ruby
```

Examples
--------

### Basic example

This is the minimal example that you can use to test Airbrake Ruby with your
project.

```ruby
require 'airbrake-ruby'

Airbrake.configure do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

begin
  1/0
rescue ZeroDivisionError => ex
  Airbrake.notify(ex)
end

puts 'Check your dashboard on http://airbrake.io'
```

### Creating a named notifier

A named notifier can co-exist with the default notifier. You can have as many
notifiers configured differently as you want.

```ruby
require 'airbrake-ruby'

# Configure first notifier for Project A.
Airbrake.configure(:project_a) do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end

# Configure second notifier for Project B.
Airbrake.configure(:project_b) do |c|
  c.project_id = 123
  c.project_key = '321'
end

params = { time: Time.now }

# Send an exception to Project A.
Airbrake.notify('Oops!', params, :project_a)

# Send an exception to Project B.
Airbrake.notify('Oops!', params, :project_b)
```

Configuration
-------------

Before using the library and its notifiers, you must to configure them. In most
cases, it is sufficient to configure only one, default, notifier.

```ruby
Airbrake.configure do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end
```

Many notifiers can co-exist at the same time. To configure a new notifier,
simply provide an argument for the `configure` method.

```ruby
Airbrake.configure(:my_notifier) do |c|
  c.project_id = 105138
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
end
```

You cannot reconfigure already configured notifiers.

### Config options

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

If your server is not able to directly reach Airbrake, you can use built-in
proxy. By default, Airbrake Ruby uses direct connection.

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

#### host

By default, it is set to `airbrake.io`. A `host` is a web address containing a
scheme ("http" or "https"), a host and a port. You can omit the port (80 will be
assumed) and the scheme ("https" will be assumed).

```ruby
Airbrake.configure do |c|
  c.host = 'http://localhost:8080'
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

```ruby
Airbrake.configure do |c|
  c.ignore_environments = [:test]
end
```

#### timeout

The number of seconds to wait for the connection to Airbrake to open.

```ruby
Airbrake.configure do |c|
  c.timeout = 10
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

#### always_async

Always send errors asynchronously. The default value is false.
If Airbrake.notify is called but no asynchronous workers are alive, the default behaviour is
to send the error synchronously. Set always_async to true to prevent this behaviour.

```ruby
Airbrake.configure do |c|
  c.always_async = true
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
  if notice[:errors].any? { |error| error[:type] == 'StandardError' }
    notice.ignore!
  end
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

##### The KeysBlacklist filter

The KeysBlacklist filter filters specific keys (parameters, session data,
environment data). Before sending the notice, filtered keys will be substituted
with the `[Filtered]` label.

It accepts Strings, Symbols & Regexps, which represent keys to be filtered.

```ruby
Airbrake.blacklist_keys([:email, /credit/i, 'password'])
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

##### The KeysWhitelist filter

The KeysWhitelist filter allows you to specify which keys should not be
filtered. All other keys will be substituted with the `[Filtered]` label.

It accepts Strings, Symbols & Regexps, which represent keys the values of which
shouldn't be filtered.

```ruby
Airbrake.whitelist([:email, /user/i, 'account_id'])
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

#### Airbrake.build_notice

Builds an [Airbrake notice][notice-v3]. This is useful, if you want to add or
modify a value only for a specific notice. When you're done modifying the
notice, send it with `Airbrake.notify` or `Airbrake.notify_sync`.

```ruby
notice = Airbrake.build_notice('App crashed!')
notice[:params][:username] = user.name
airbrake.notify_sync(notice)
```

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

  # Closes a named notifier.
  Airbrake.close(:my_notifier)
end
```

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

Accesses a notice's modifiable payload, which can be read or
filtered. Modifiable payload includes:

* `:errors`
* `:context`
* `:environment`
* `:session`
* `:params`

```ruby
notice[:params][:my_param] = 'foobar'
```

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

Supported Rubies
----------------

* CRuby >= 1.9.2
* JRuby >= 1.9-mode
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
[notice-v3]: https://airbrake.io/docs/#create-notice-v3
[project-idkey]: https://s3.amazonaws.com/airbrake-github-assets/airbrake-ruby/project-id-key.png
[issues]: https://github.com/airbrake/airbrake-ruby/issues
[twitter]: https://twitter.com/airbrake
[keysblacklist]: https://github.com/airbrake/airbrake-ruby/blob/master/lib/airbrake-ruby/filters/keys_blacklist.rb
[keyswhitelist]: https://github.com/airbrake/airbrake-ruby/blob/master/lib/airbrake-ruby/filters/keys_whitelist.rb
[golang]: https://golang.org/
[semver]: https://img.shields.io/:semver-1.1.0-brightgreen.svg?style=flat
[yard-api]: http://www.rubydoc.info/gems/airbrake-ruby
[arthur-ruby]: https://s3.amazonaws.com/airbrake-github-assets/airbrake-ruby/arthur-ruby.jpg
