Airbrake Ruby Changelog
=======================

### master

### [v2.8.1][v2.8.1] (January 31, 2018)

* Blacklisted the `vendor/bundle` path for code hunks. This fixes unwanted code
  hunk reporting for gems inside `root_directory`, which causes every notice to
  go over the notice limit.
  ([#302](https://github.com/airbrake/airbrake-ruby/pull/302))

### [v2.8.0][v2.8.0] (January 16, 2018)

* Added support for Regexps for the `ignore_environments` option
  ([#299](https://github.com/airbrake/airbrake-ruby/pull/299))

### [v2.7.1][v2.7.1] (January 8, 2018)

* Fixed disabling of code hunks. It was impossible to disable them
  ([#295](https://github.com/airbrake/airbrake-ruby/pull/295))

### [v2.7.0][v2.7.0] (December 13, 2017)

* Stopped gathering thread information by default
  ([#292](https://github.com/airbrake/airbrake-ruby/pull/292))

### [v2.6.2][v2.6.2] (December 4, 2017)

* Additional fixes for circular references in the new truncator
  ([#288](https://github.com/airbrake/airbrake-ruby/pull/288)). Again, if you're
  on v2.6, please upgrade as soon as possible

### [v2.6.1][v2.6.1] (December 1, 2017)

* Fixed circular references in the new truncator
  ([#286](https://github.com/airbrake/airbrake-ruby/pull/286)). All v2.6.0 users
  are *highly recommended* to upgrade.

### [v2.6.0][v2.6.0] (November 9, 2017)

* Reworked truncation to not mutate given payload (params) and made it freeze it
  after the truncation is done (to prevent future mutations)
  ([#283](https://github.com/airbrake/airbrake-ruby/pull/283))

### [v2.5.1][v2.5.1] (October 26, 2017)

* Fixed the bug when both `whitelist_keys` and `blacklist_keys` are specified
  ([#277](https://github.com/airbrake/airbrake-ruby/pull/277))
* Started passing project key through the `Authorization` header instead of the
  `key` query parameter
  ([#278](https://github.com/airbrake/airbrake-ruby/pull/278))

### [v2.5.0][v2.5.0] (October 20, 2017)

* Added code hunks support (surrounding lines around every stack frame)
  ([#273](https://github.com/airbrake/airbrake-ruby/pull/273))

### [v2.4.2][v2.4.2] (October 12, 2017)

* Fixed bug when HTTP headers couldn't be filtered
  ([#257](https://github.com/airbrake/airbrake-ruby/pull/257))

### [v2.4.1][v2.4.1] (October 12, 2017)

* Added support for code hunks. This feature is not officially released and
  doesn't work yet ([#258](https://github.com/airbrake/airbrake-ruby/pull/258))

### [v2.4.0][v2.4.0] (September 20, 2017)

* Started appending `$PROGRAM_NAME` to `environment`
  ([#251](https://github.com/airbrake/airbrake-ruby/pull/251))
* Added support for rate limiting by IP
  ([#253](https://github.com/airbrake/airbrake-ruby/pull/253))

### [v2.3.2][v2.3.2] (July 26, 2017)

* Every notice started carrying original exception, accessible via the notice
  stash ([#241](https://github.com/airbrake/airbrake-ruby/pull/241))

### [v2.3.1][v2.3.1] (July 15, 2017)

* Fix response parser not parsing errors
  ([#239](https://github.com/airbrake/airbrake-ruby/pull/239))

### [v2.3.0][v2.3.0] (June 6, 2017)

* Added a new helper method `Airbrake.configured?`
  ([#237](https://github.com/airbrake/airbrake-ruby/pull/237))

### [v2.2.7][v2.2.7] (June 24, 2017)

* Fixed unwanted mutation of `params` on `Airbrake.notify(ex, params)`
  ([#234](https://github.com/airbrake/airbrake-ruby/pull/234))

### [v2.2.6][v2.2.6] (June 15, 2017)

* Fixed segfault in `ThreadFilter` on Ruby 2.1.3
  ([#231](https://github.com/airbrake/airbrake-ruby/pull/231))

### [v2.2.5][v2.2.5] (May 23, 2017)

* Fixed bug when the block form of `notify` would run its block for ignored
  notices: ([#226](https://github.com/airbrake/airbrake-ruby/pull/226))

### [v2.2.4][v2.2.4] (May 17, 2017)

* Fixed bug in `ThreadFilter`, when it attaches an object, which can't be dumped
  to JSON. As result, `ThreadFilter` has become stricter: it only allows
  instances of whitelisted classes (primitives)
  ([#224](https://github.com/airbrake/airbrake-ruby/pull/224))

### [v2.2.3][v2.2.3] (May 11, 2017)

* Fixed bug in keys filters while trying to filter a non Symbol/String key when
  there's a Regexp ignore pattern defined
  ([#213](https://github.com/airbrake/airbrake-ruby/pull/213))

### [v2.2.2][v2.2.2] (May 5, 2017)

* Fixed `SystemStackError` while using the thread filter with RSpec
  ([#208](https://github.com/airbrake/airbrake-ruby/pull/208))

### [v2.2.1][v2.2.1] (May 4, 2017)

* Fixed segfault on Ruby 2.1 while using the thread filter
  ([#206](https://github.com/airbrake/airbrake-ruby/pull/206))

### [v2.2.0][v2.2.0] (May 1, 2017)

* Make `notify/notify_sync` accept a block, which yields an `Airbrake::Notice`
  ([#201](https://github.com/airbrake/airbrake-ruby/pull/201))
* Started sending `context/severity`, which is set to `error`
  ([#202](https://github.com/airbrake/airbrake-ruby/pull/202))

### [v2.1.0][v2.1.0] (April 27, 2017)

* Return `Airbrake::NilNotifier` when no notifiers are configured and
  `Airbrake.[]` is called
  ([#191](https://github.com/airbrake/airbrake-ruby/pull/191))
* Fixed the `host` option not recognizing hosts with subpaths such as
  `https://example.com/subpath/`
  ([#192](https://github.com/airbrake/airbrake-ruby/pull/192))
* Fixed the order of invokation of library & user defined filters, so the user
  filters are always invoked after all the library filters
  ([#195](https://github.com/airbrake/airbrake-ruby/pull/195))
* Started attaching current thread information (including thread & fiber
  variables) ([#198](https://github.com/airbrake/airbrake-ruby/pull/198))

### [v2.0.0][v2.0.0] (March 21, 2017)

* **IMPORTANT:** Removed the `component/action` API deprecated
  in [v1.7.0](#v170-january-20-2017)
  ([#169](https://github.com/airbrake/airbrake-ruby/pull/169))
* **IMPORTANT:** Removed `notifier_name` argument deprecated
  in [v1.8.0](#v180-february-23-2017)
  ([#176](https://github.com/airbrake/airbrake-ruby/pull/176))
* Fixed default `root_directory` not resolving symlinks
  ([#180](https://github.com/airbrake/airbrake-ruby/pull/180))
* Fixed parsing JRuby exceptions that don't subclass `Java::JavaLang::Throwable`
  ([#184](https://github.com/airbrake/airbrake-ruby/pull/184))

### [v1.8.0][v1.8.0] (February 23, 2017)

* **IMPORTANT:** Deprecated `notifier_name` argument for all public API methods
  such as `Airbrake.notify('oops', {}, :my_notifier)`
  ([#168](https://github.com/airbrake/airbrake-ruby/pull/168))
* `root_directory` is now defaulted to either `Bundler.root` or current working
  directory ([#171](https://github.com/airbrake/airbrake-ruby/pull/171))

### [v1.7.1][v1.7.1] (February 3, 2017)

* **IMPORTANT:** fixed bug when `blacklist_keys/whitelist_keys` does not filter
  keys at all ([#159](https://github.com/airbrake/airbrake-ruby/pull/159))

### [v1.7.0][v1.7.0] (January 20, 2017)

* **IMPORTANT:** support for Ruby 1.9.2, 1.9.3 & JRuby (1.9-mode) is dropped
  ([#146](https://github.com/airbrake/airbrake-ruby/pull/146))
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
[v1.7.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.7.1
[v1.8.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.8.0
[v2.0.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.0.0
[v2.1.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.1.0
[v2.2.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.0
[v2.2.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.1
[v2.2.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.2
[v2.2.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.3
[v2.2.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.4
[v2.2.5]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.5
[v2.2.6]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.6
[v2.2.7]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.2.7
[v2.3.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.3.0
[v2.3.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.3.1
[v2.3.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.3.2
[v2.4.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.4.0
[v2.4.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.4.1
[v2.4.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.4.2
[v2.5.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.5.0
[v2.5.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.5.1
[v2.6.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.6.0
[v2.6.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.6.1
[v2.6.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.6.2
[v2.7.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.7.0
[v2.7.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.7.1
[v2.8.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.8.0
[v2.8.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.8.1
