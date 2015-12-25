Airbrake Ruby Changelog
=======================

### master

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
