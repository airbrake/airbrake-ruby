Airbrake Ruby Changelog
=======================

### master

### [v1.3.2][v1.3.2] (May 27, 2016)

* Fixed bug when the library raises unwanted exception, when current environment
  is ignored and a notifier is given an exception with bad backtrace
  ([#85](https://github.com/airbrake/airbrake-ruby/pull/85))

### [v1.3.1][v1.3.1] (May 13, 2016)

* Fixed infinite loop bug while trying to truncate a notice
  ([#83](https://github.com/airbrake/airbrake-ruby/pull/83))

### [v1.3.0][v1.3.0] (May 10, 2016)

* **IMPORTANT:** stopped raising the `the 'default' notifier isn't configured`
  error when Airbrake is not configured. Instead, when a notifier *is not*
  configured, all public API methods will be returning `nil`.
  ([#75](https://github.com/airbrake/airbrake-ruby/pull/75))

  Make sure that if you use `Airbrake.build_notice` or `Airbrake.notify_sync`,
  you protect yourself from a possible crash by handling the return value (it
  might be `nil`).

### [v1.2.4][v1.2.4] (May 4, 2016)

* Fixed bug when trying to truncate frozen strings
  ([#73](https://github.com/airbrake/airbrake-ruby/pull/73))

### [v1.2.3][v1.2.3] (April 22, 2016)

* Fixed `URI::InvalidURIError` while trying to filter non-standard URLs
  ([#70](https://github.com/airbrake/airbrake-ruby/pull/70))

### [v1.2.2][v1.2.2] (April 5, 2016)

* Fixed bug in `Notifier#notify` where the `params` Hash is ignored if the first
  argument is an `Airbrake::Notice`
  ([#66](https://github.com/airbrake/airbrake-ruby/pull/66))

### [v1.2.1][v1.2.1] (March 21, 2016)

* Fixed bug with regard to proxy configuration, when the library unintentionally
  overwrites the environment proxy
  ([#63](https://github.com/airbrake/airbrake-ruby/pull/63))

### [v1.2.0][v1.2.0] (March 11, 2016)

* **IMPORTANT:** changed public API of blacklist and whitelist filters. Instead
  of `Airbrake.blacklist_keys` and `Airbrake.whitelist_keys` please use the
  respective new config options
  ([#56](https://github.com/airbrake/airbrake-ruby/pull/56)):

  ```ruby
  # v1.1.0 and older
  Airbrake.blacklist_keys([:password, /credit/i])
  Airbrake.whitelist_keys([:page_id, 'user'])

  # New way
  Airbrake.configure do |c|
    c.blacklist_keys = [:password, /credit/i]
    c.whitelist_keys = [:page_id, 'user']
  end
  ```

  The old API is still supported, but *deprecated*.

* **IMPORTANT**: dropped support for reporting critical exceptions that
  terminate the process. This bit of functionality was moved to the
  [airbrake gem](https://github.com/airbrake/airbrake/pull/526) instead
  ([#61](https://github.com/airbrake/airbrake-ruby/pull/61))
* Started filtering the context payload
  ([#55](https://github.com/airbrake/airbrake-ruby/pull/55))
* Fixed bug when similar keys would be filtered out using non-regexp values for
  `Airbrake.blacklist/whitelist_keys`
  ([#54](https://github.com/airbrake/airbrake-ruby/pull/54))
* Fixed bug when async workers die due to various unexpected network errors
  ([#52](https://github.com/airbrake/airbrake-ruby/pull/52))

### [v1.1.0][v1.1.0] (February 25, 2016)

* Fixed bug in Ruby < 2.2, when trying to encode components while filtering
  ([#45](https://github.com/airbrake/airbrake-ruby/pull/45))
* Stopped blocking on full queue when sending errors asynchronously
  ([#47](https://github.com/airbrake/airbrake-ruby/pull/47))
* Added the `timeout` option
  ([#46](https://github.com/airbrake/airbrake-ruby/pull/46))

### [v1.0.4][v1.0.4] (February 2, 2016)

* Started attaching the hostname information by default
  ([#41](https://github.com/airbrake/airbrake-ruby/pull/41))

### [v1.0.3][v1.0.3] (January 18, 2016)

* Improved parsing of backtraces
  ([#25](https://github.com/airbrake/airbrake-ruby/pull/25),
  [#29](https://github.com/airbrake/airbrake-ruby/pull/29),
  [#30](https://github.com/airbrake/airbrake-ruby/pull/30))
* Made sure that generated notices always have a backtrace
  ([#21](https://github.com/airbrake/airbrake-ruby/pull/21))
* Made the asynchronous delivery mechanism more robust
  ([#26](https://github.com/airbrake/airbrake-ruby/pull/26))
* Improved `SystemExit` handling by ignoring it on a different level, which
  fixed issues with the Rake integration for the [airbrake gem][airbrake-gem]
  gem ([#32](https://github.com/airbrake/airbrake-ruby/pull/32))

### [v1.0.2][v1.0.2] (January 3, 2016)

* Ignored `SystemExit` in the `at_exit` hook, which has fixed the Rake
  integration for the [airbrake gem][airbrake-gem] gem
  ([#14](https://github.com/airbrake/airbrake-ruby/pull/14))

### [v1.0.1][v1.0.1] (December 22, 2015)

* Fixed the `Airbrake.add_filter` block API
  ([#10](https://github.com/airbrake/airbrake-ruby/pull/10))

### [v1.0.0][v1.0.0] (December 18, 2015)

* Improved backtrace parsing support
  ([#4](https://github.com/airbrake/airbrake-ruby/pull/4))

### [v1.0.0.rc.1][v1.0.0.rc.1] (December 11, 2015)

* Initial release

[v1.0.0.rc.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.0.rc.1
[v1.0.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.0
[v1.0.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.1
[v1.0.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.2
[v1.0.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.3
[v1.0.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.4
[v1.1.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.1.0
[v1.2.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.0
[v1.2.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.1
[v1.2.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.2
[v1.2.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.3
[v1.2.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.2.4
[v1.3.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.3.0
[v1.3.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.3.1
[v1.3.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.3.2
