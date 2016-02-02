Airbrake Ruby Changelog
=======================

### master

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

[airbrake-gem]: https://github.com/airbrake/airbrake
[v1.0.0.rc.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.0.rc.1
[v1.0.0]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.0
[v1.0.1]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.1
[v1.0.2]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.2
[v1.0.3]: https://github.com/airbrake/airbrake-ruby/releases/tag/v1.0.3
