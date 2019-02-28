Airbrake Ruby Changelog
=======================

### master

### [v4.1.0][v4.1.0] (Feburary 28, 2019)

* `add_filter` & `add_performance_filter` add filters even when Airbrake is not
  configured ([#445](https://github.com/airbrake/airbrake-ruby/pull/445),
  [#451](https://github.com/airbrake/airbrake-ruby/pull/451))

### [v4.0.1][v4.0.1] (Feburary 26, 2019)

* Fixed bug in `Airbrake.configure` not setting `logger` properly
  ([#442](https://github.com/airbrake/airbrake-ruby/pull/442))
* Fixed bug with `Airbrake::Config.instance` returning a broken Config instance
  ([#443](https://github.com/airbrake/airbrake-ruby/pull/443))

### [v4.0.0][v4.0.0] (Feburary 25, 2019)

* Removed support for deprecated `Airbrake.configure(:name)`
  ([#429](https://github.com/airbrake/airbrake-ruby/pull/429))
* Renamed `Airbrake.create_deploy` to `Airbrake.notify_deploy`
  ([#427](https://github.com/airbrake/airbrake-ruby/pull/427))
* Deleted deprecated `Airbrake::Notifier` & `Airbrake::NilNotifier` constants
  ([#425](https://github.com/airbrake/airbrake-ruby/pull/425))
* Deleted deprecated `Config#route_stats`, `Config#route_stats_flush_period`
  ([#425](https://github.com/airbrake/airbrake-ruby/pull/425))
* `PerformanceNotifier`, `NoticeNotifier` & `DeployNotifier` stopped accepting
  deprecated Hash as a `config` object
  ([#425](https://github.com/airbrake/airbrake-ruby/pull/425))
* Deleted deprecated `Airbrake#[]`
  ([#432](https://github.com/airbrake/airbrake-ruby/pull/432))
* Deleted deprecated `Airbrake#notifiers`
  ([#433](https://github.com/airbrake/airbrake-ruby/pull/433))

### [v3.2.6][v3.2.6] (Feburary 25, 2019)

* Reduced clutter of `DeployNotifier` and `PerformanceNotifier` when
  `inspect`ing ([#423](https://github.com/airbrake/airbrake-ruby/pull/423))
* Deprecated `Airbrake.create_deploy` in favour of `Airbrake.notify_deploy`
  ([#426](https://github.com/airbrake/airbrake-ruby/pull/426))
* Deprecated `Airbrake.configure(:name)` in favour of `Airbrake.configure` or
  `Airbrake::NoticeNotifier.new`
  ([#430](https://github.com/airbrake/airbrake-ruby/pull/430))
* Deprecated `Airbrake#[]` in favour of `Airbrake::NoticeNotifier.new`
  ([#431](https://github.com/airbrake/airbrake-ruby/pull/431))
* Deprecated `Airbrake#notifiers`
  ([#434](https://github.com/airbrake/airbrake-ruby/pull/434))

### [v3.2.5][v3.2.5] (Feburary 20, 2019)

* Added the ability to attach caller location to `Airbrake::Query` (function,
  file, line) ([#419](https://github.com/airbrake/airbrake-ruby/pull/419))
* Added the ability to attach environment to `Airbrake::Query` &
  `Airbrake::Request`
  ([#421](https://github.com/airbrake/airbrake-ruby/pull/421))

### [v3.2.4][v3.2.4] (Feburary 15, 2019)

* Fixed ``undefined method `split' for nil:NilClass`` in `GitRepositoryFilter`
  when `git` is not installed
  ([#417](https://github.com/airbrake/airbrake-ruby/pull/417))

### [v3.2.3][v3.2.3] (Feburary 12, 2019)

* Fixed `no implicit conversion of Array into String` raised by
  `FilterChain#inspect` when no filters were added
  ([#414](https://github.com/airbrake/airbrake-ruby/pull/414))

### [v3.2.2][v3.2.2] (Febuary 11, 2019)

* Fixed ``undefined method `notify_request'`` when calling
  `Airbrake.notify_request` (added backwards compatibility)
  ([#411](https://github.com/airbrake/airbrake-ruby/pull/411))

### [v3.2.1][v3.2.1] (Febuary 11, 2019)

* Fixed `Malformed version number string` in `GitRepositoryFilter` when
  detecting Git version
  ([#409](https://github.com/airbrake/airbrake-ruby/pull/409))
* Fixed JRuby installing `rbtree3` instead of `rbtree-jruby`
  ([#408](https://github.com/airbrake/airbrake-ruby/pull/408))

### [v3.2.0][v3.2.0] (February 8, 2019)

* Dropped `tdigest` dependency. Airbrake Ruby imports that code, instead
  ([#400](https://github.com/airbrake/airbrake-ruby/pull/400))
* Started depending on [rbtree3](https://rubygems.org/gems/rbtree3) instead of
  [rbtree](https://rubygems.org/gems/rbtree), which fixed [`_dump': instance of
  IO needed (TypeError)`](https://github.com/airbrake/airbrake/issues/894) when
  trying to dump an RBTree
  ([#400](https://github.com/airbrake/airbrake-ruby/pull/400))
* Added `Airbrake.notify_query` to send SQL queries to Airbrake
  ([#379](https://github.com/airbrake/airbrake-ruby/pull/376))
* Added `Airbrake.add_performance_filter` and
  `Airbrake.delete_performance_filter` to filter out sensitive SQL query and
  route data ([#395](https://github.com/airbrake/airbrake-ruby/pull/395))
* Added `Airbrake.notifiers` to access the new performance notifier
  ([#398](https://github.com/airbrake/airbrake-ruby/pull/398))
* Deprecated `config.route_stats` in favor of `config.performance_stats`
  ([#381](https://github.com/airbrake/airbrake-ruby/pull/381))
* Deprecated `Airbrake::Notifier` in favor of `Airbrake::NoticeNotifier`
  ([#386](https://github.com/airbrake/airbrake-ruby/pull/386))
* Fixed time truncation on `Airbrake.notify_request`, which wasn't respecting
  UTC offset ([#394](https://github.com/airbrake/airbrake-ruby/pull/394))
* Fixed bug where `GitRepositoryFilter` invokes `get-url`, which doesn't exist
  on Git 2.6 and lower
  ([#399](https://github.com/airbrake/airbrake-ruby/pull/399))
  ([#404](https://github.com/airbrake/airbrake-ruby/pull/404))

### [v3.1.0][v3.1.0] (January 23, 2019)

* Added `Airbrake.delete_filter`, which can be used for deleting filters added
  via `Airbrake.add_filter`
  ([#376](https://github.com/airbrake/airbrake-ruby/pull/376))

### [v3.0.0][v3.0.0] (January 16, 2019)

* Disabled `route_stats` by default. If you were using our release candidate
  gems, all you need to do is to set it to `true` in your config
  ([#372](https://github.com/airbrake/airbrake-ruby/pull/372))

### [v3.0.0.rc.9][v3.0.0.rc.9] (December 3, 2018)

* Added the `route_stats` option, which enables/disables route stat
  collection. Route stat collection also respects current environment now, which
  means the notifier won't be collecting route information for ignored
  environments ([#369](https://github.com/airbrake/airbrake-ruby/pull/369))
* Fixed `NoMethodError` in `GitLastCheckoutFilter`
  ([#368](https://github.com/airbrake/airbrake-ruby/pull/368))

### [v3.0.0.rc.8][v3.0.0.rc.8] (November 21, 2018)

* Reverted the fix applied in v3.0.0.rc.7 because it didn't do what it claimed
  ([#364](https://github.com/airbrake/airbrake-ruby/pull/364))

### [v3.0.0.rc.7][v3.0.0.rc.7] (November 19, 2018)

* Possibly fixed the problem where `RouteSender` sends routes with 0 count
  ([#362](https://github.com/airbrake/airbrake-ruby/pull/362))

### [v3.0.0.rc.6][v3.0.0.rc.6] (November 13, 2018)

* Fixed incorrect route statistics reporting (seconds instead of milliseconds)
  ([#360](https://github.com/airbrake/airbrake-ruby/pull/360))

### [v3.0.0.rc.5][v3.0.0.rc.5] (November 12, 2018)

* Renamed `Airbrake.inc_request` to `Airbrake.notify_request` and changed its
  signature ([#358](https://github.com/airbrake/airbrake-ruby/pull/358))

### [v3.0.0.rc.4][v3.0.0.rc.4] (November 6, 2018)

* Updated `/routes-stats` API to v5
  ([#355](https://github.com/airbrake/airbrake-ruby/pull/355))

### [v3.0.0.rc.3][v3.0.0.rc.3] (November 6, 2018)

* Set tdigest compression to 20
  ([#354](https://github.com/airbrake/airbrake-ruby/pull/354))

### [v3.0.0.rc.2][v3.0.0.rc.2] (October 30, 2018)

* **Dropped support for Ruby 2.0**
  ([#352](https://github.com/airbrake/airbrake-ruby/pull/352))
* Made `Airbrake::Notifier#inspect` less verbose
  ([#350](https://github.com/airbrake/airbrake-ruby/pull/350))
* Added new dependency `tdigest`. Started sending tdigests to the backend
  ([#351](https://github.com/airbrake/airbrake-ruby/pull/351))

### [v2.13.0.rc.1][v2.13.0.rc.1] (October 26, 2018)

* Added support for route stats
  ([#348](https://github.com/airbrake/airbrake-ruby/pull/348))

### [v2.12.0][v2.12.0] (October 11, 2018)

* Stopped passing project id on `Airbrake.create_deploy` as a query param
  ([#339](https://github.com/airbrake/airbrake-ruby/pull/339))
* Changed the endpoint that Airbrake Ruby sends errors to.

  Before: `https://airbrake.io/api/v4/projects/PROJECT_ID/notices`

  After: `https://api.airbrake.io/api/v4/projects/PROJECT_ID/notices`

  The endpoint neither accepts anything new nor removes existing functionality.
  ([#340](https://github.com/airbrake/airbrake-ruby/pull/340))
* Added the ability to automatically track deploys if an app is deployed with
  `.git` in the root of the project
  ([#341](https://github.com/airbrake/airbrake-ruby/pull/341))

  Note: this feature is enabled only for certain accounts. Further details as to
  how to use it will be published in the README once it's released to everybody.

* Cached revision of `GitRevisionFilter`, so we don't repeatedly
  read the file ([#342](https://github.com/airbrake/airbrake-ruby/pull/342))
* Changed the order of execution of inline filters (added via `Airbrake.notify
  do ... end`) and the `Airbrake.add_filter` filters. Now the former is being
  executed first (used to be executed last)
  ([#345](https://github.com/airbrake/airbrake-ruby/pull/345))

### [v2.11.0][v2.11.0] (June 27, 2018)

* Added `GitRevisionFilter`
  ([#333](https://github.com/airbrake/airbrake-ruby/pull/333))

### [v2.10.0][v2.10.0] (May 3, 2018)

* Added the `versions` option
  ([#327](https://github.com/airbrake/airbrake-ruby/pull/327))
* Added `DependencyFilter` (optional)
  ([#328](https://github.com/airbrake/airbrake-ruby/pull/328))

### [v2.9.0][v2.9.0] (April 26, 2018)

* Changed format for `[GEM_ROOT]` & `[PROJECT_ROOT]` placeholders to
  `/GEM_ROOT` & `/PROJECT_ROOT` respectively. This improves searching
  capabilities in the Airbrake
  dashboard. ([#311](https://github.com/airbrake/airbrake-ruby/pull/311))
* Fixed `TypeError: can't move to the enclosed thread group` when
  using `notify` at the same time from multiple threads
  ([#316](https://github.com/airbrake/airbrake-ruby/pull/316))
* Added `Airbrake.merge_context` that allows reporting data on different scopes
  along with the error
  ([#317](https://github.com/airbrake/airbrake-ruby/pull/317))

### [v2.8.3][v2.8.3] (March 12, 2018)

* Fixed bug introduced in v2.8.2 in blacklist/whitelist filtering. All
  v2.8.2 users must upgrade to the recent version
  ([#309](https://github.com/airbrake/airbrake-ruby/pull/309))

### [v2.8.2][v2.8.2] (March 5, 2018)

* Fixed bug where params inside arrays couldn't be
  blacklisted/whitelisted
  ([#306](https://github.com/airbrake/airbrake-ruby/pull/306))

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
[v2.8.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.8.2
[v2.8.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.8.3
[v2.9.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.9.0
[v2.10.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.10.0
[v2.11.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.11.0
[v2.12.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.12.0
[v2.13.0.rc.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v2.13.0.rc.1
[v3.0.0.rc.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.2
[v3.0.0.rc.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.3
[v3.0.0.rc.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.4
[v3.0.0.rc.5]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.5
[v3.0.0.rc.6]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.6
[v3.0.0.rc.7]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.7
[v3.0.0.rc.8]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.8
[v3.0.0.rc.9]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0.rc.9
[v3.0.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.0.0
[v3.1.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.1.0
[v3.2.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.0
[v3.2.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.1
[v3.2.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.2
[v3.2.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.3
[v3.2.4]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.4
[v3.2.5]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.5
[v3.2.6]: https://github.com/airbrake/airbrake-ruby/releases/tag/v3.2.6
[v4.0.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v4.0.0
[v4.0.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v4.0.1
[v4.1.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v4.1.0
