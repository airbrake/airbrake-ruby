Airbrake Ruby Changelog
=======================

### master

### [v1.7.0][v1.7.0] (January 20, 2017)

* **IMPORTANT:** support for Ruby 1.9.2, 1.9.3 & JRuby (1.9-mode) is dropped
  ([#146](https://github.com/airbrake/airbrake/pull/146))
* **IMPORTANT:** added the promise API
  ([#143](https://github.com/airbrake/airbrake-ruby/pull/143))
* **IMPORTANT:** deprecated the `component/action` API (when setting through
  `params`) ([#151](https://github.com/airbrake/airbrake-ruby/pull/151))
* Improved parsing of JRuby frames which include classloader
  ([#140](https://github.com/airbrake/airbrake-ruby/pull/140))
* Fixed bug in the `host` option, when it is configured with a slug
  ([#145](https://github.com/airbrake/airbrake-ruby/pull/145))
* Added `Notice#stash` ([#152](https://github.com/airbrake/airbrake-ruby/pull/152))

### [v1.6.0][v1.6.0] (October 18, 2016)

* Added support for blacklisting/whitelisting using procs
  ([#108](https://github.com/airbrake/airbrake-ruby/pull/108))
* Deleted deprecated public API methods (whitelisting, blacklisting)
  ([#125](https://github.com/airbrake/airbrake-ruby/pull/125))
* Fixed support for Ruby 2.0.* not being able to report ExecJS exceptions
  ([#130](https://github.com/airbrake/airbrake-ruby/pull/130))
* Reduced notice size (small improvement, which affects every single notice)
  ([#132](https://github.com/airbrake/airbrake-ruby/pull/132))

### [v1.5.0][v1.5.0] (September 9, 2016)

* Added support for custom exception attributes
  ([#113](https://github.com/airbrake/airbrake-ruby/pull/113))
* Started validating the 'environment' config option (a warning will be printed,
  if it is misconfigured)
  ([#115](https://github.com/airbrake/airbrake-ruby/pull/115))
* Fixed error while filtering unparseable backtraces
  ([#120](https://github.com/airbrake/airbrake-ruby/pull/120))
* Improved support for parsing JRuby backtraces
  ([#119](https://github.com/airbrake/airbrake-ruby/pull/119))
* Fixed bug where individual user fields couldn't be filtered
  ([#118](https://github.com/airbrake/airbrake-ruby/pull/118))

### [v1.4.6][v1.4.6] (August 18, 2016)

* Fixed support for ExecJS backtraces for Ruby 1.9.3 sometimes resulting in
  `NameError` ([#110](https://github.com/airbrake/airbrake-ruby/pull/110))

### [v1.4.5][v1.4.5] (August 15, 2016)

* Added support for CoffeeScript/ExecJS backtraces
  ([#107](https://github.com/airbrake/airbrake-ruby/pull/107))

### [v1.4.4][v1.4.4] (July 11, 2016)

* Added support for PL/SQL exceptions raised by
  [ruby-oci8](https://github.com/kubo/ruby-oci8)
  ([#99](https://github.com/airbrake/airbrake-ruby/pull/99))

### [v1.4.3][v1.4.3] (June 10, 2016)

* Made types of the `ignore_environments` and `environment` option values not to
  rely on each other when deciding if the current environment is ignored
  ([#94](https://github.com/airbrake/airbrake-ruby/pull/94))

### [v1.4.2][v1.4.2] (June 8, 2016)

* Print warning when the `environment` option is not configured, but
  `ignore_environments` is
  ([#92](https://github.com/airbrake/airbrake-ruby/pull/92))

### [v1.4.1][v1.4.1] (June 6, 2016)

* Allow passing a String for `project_id`
  ([#89](https://github.com/airbrake/airbrake-ruby/pull/89))

### [v1.4.0][v1.4.0] (June 6, 2016)

* Stopped raising error when the notifier lacks either project ID or project key
  and also told to ignore current environment. As the result, empty string for
  `project_key` is also validated now (forbidden)
  ([#87](https://github.com/airbrake/airbrake-ruby/pull/87))

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
  fixed issues with the Rake integration for the
  [airbrake gem](https://github.com/airbrake/airbrake)
  ([#32](https://github.com/airbrake/airbrake-ruby/pull/32))

### [v1.0.2][v1.0.2] (January 3, 2016)

* Ignored `SystemExit` in the `at_exit` hook, which has fixed the Rake
  integration for the [airbrake gem](https://github.com/airbrake/airbrake)
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
[v1.4.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.0
[v1.4.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.1
[v1.4.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.2
[v1.4.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.3
[v1.4.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.4
[v1.4.5]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.5
[v1.4.6]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.4.6
[v1.5.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.5.0
[v1.6.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.6.0
[v1.7.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.7.0
