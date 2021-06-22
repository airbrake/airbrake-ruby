How to contribute
=================

Pull requests
-------------

We love your contributions, thanks for taking the time to contribute!

It's really easy to start contributing, just follow these simple steps:

1. [Fork][fork-article] the [repo][airbrake-ruby]:

2. Run the test suite to make sure the tests pass:

  ```shell
  bundle exec rake
  ```

3. [Create a separate branch][branch], commit your work and push it to your
   fork. If you add comments, please make sure that they are compatible with
   [YARD][yard]:

  ```
  git checkout -b my-branch
  git commit -am
  git push origin my-branch
  ```

4. Verify that your code doesn't offend Rubocop:

  ```
  bundle exec rubocop
  ```

5. Verify that your code's documentation is correct:

  ```
  bundle exec yardoc --fail-on-warning --no-progress --readme=README
  ```

6. Run the test suite again (new tests are always welcome):

  ```
  bundle exec rake
  ```

7. [Make a pull request][pr]

Submitting issues
-----------------

Our [issue tracker][issues] is a perfect place for filing bug reports or
discussing possible features. If you report a bug, consider using the following
template (copy-paste friendly):

```
* Airbrake version: {YOUR VERSION}
* Ruby version: {YOUR VERSION}
* Framework name & version: {YOUR DATA}

#### Airbrake config

    # YOUR CONFIG
    #
    # Make sure to delete any sensitive information
    # such as your project id and project key.

#### Description

{We would be thankful if you provided steps to reproduce the issue, expected &
actual results, any code snippets or even test repositories, so we could clone
it and test}
```

[airbrake-ruby]: https://github.com/airbrake/airbrake-ruby
[fork-article]: https://help.github.com/articles/fork-a-repo
[branch]: https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/
[pr]: https://help.github.com/articles/using-pull-requests
[issues]: https://github.com/airbrake/airbrake-ruby/issues
[yard]: http://yardoc.org/
