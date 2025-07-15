# Change Log

## 2.1.0 / 2025-07-14

* Added options:

  * `branch` specify git branch to check out (if required) before fetching file.
     A warning is generated if the branch is not defined.

     Example, checks out branch `example1` before including file:

     ```html
     branch='example1'
     ```

  * `branch_restore` like `branch` but restores the branch after including the file.

     Example, checks out branch `example1` before including file, then restores whatever branch was active before
     flexible include was invoked:

     ```html
     branch_restore='example1'
     ```

* Replaced the CSS class `bg_yellow` with `bg_yellow_nopad`.


## 2.0.25 / 2024-12-11

* Fixed `from` / `to` / `until` issue


## 2.0.24 / 2024-00-20

* Made compatible with `jekyll_plugin_support` v1.0.2


## 2.0.23 / 2024-07-22

* Made compatible with `jekyll_plugin_support` v1.0.0


## 2.0.22 / 2024-02-27

* Improved error reporting


## 2.0.21 / 2023-11-16

* Restructured code
* `die_on_file_error` and `die_on_path_denied` work again.
* Specifying the file name without using a name/value parameter works again.


## 2.0.20 / 2023-05-30

* Updated dependencies


## 2.0.19 / 2023-04-05

* Added attribution support


## 2.0.18 / 2023-03-24

* The following are now parsed property:
  `die_on_file_error`, `die_on_path_denied`, `die_on_run_error`, `die_on_path_denied`, and `die_on_other_error`.


## 2.0.17 / 2023-03-22

* Added `repo` and `git_ref` parameters, so files can be retrieved from git repositories at a given commit or tag.


## 2.0.16 / 2023-02-19

* Replaced hard-coded CSS in `denied` method with `flexible_error` class in
  `demo/assets/css/style.css`.
* Added `-e` and `-x` options to `demo/_bin/debug`.
* Added configuration section `flexible_include` with supported parameters
  `die_on_file_error`, `die_on_path_denied`, `die_on_run_error`,
  `die_on_path_denied` and `die_on_other_error`.
* Fixed `undefined method 'path'` that occurred when `FLEXIBLE_INCLUDE_PATHS` was specified.


## 2.0.15 / 2023-02-18

* Replaced dependency `key-value-parser` with `jekyll_plugin_support`.
* Added `demo` website.
* Improved the documentation.
* Updated Rubocop configuration.
* Added `strip` option.


## 2.0.14 / 2022-09-27

* Added `key-value-parser` as a dependency.


## 2.0.13 / 2022-04-24

* Added `highlight` regex option, for highlighting.
* Added `number` option, for numbered lines.

## 2.0.12 / 2022-04-22
  * Exits with an error message if an environment variable included in the value
    of `FLEXIBLE_INCLUDE_PATHS` is undefined.

## 2.0.11 / 2022-04-15
  * Added & => &amp; to the escaped characters.

## 2.0.10 / 2022-04-15
  * Fixed nil pointer.

## 2.0.9 / 2022-04-15
  * Changed how path matching was implemented.

## 2.0.8 / 2022-04-14
  * Added the ability to restrict arbitrary command execution, and specify the allowable directories to read from.

## 2.0.7 / 2022-04-14
  * Added `file=` option, so the included file or process is better defined. This option is not required; the file/process can be specified without it as before.
  * Documented `data-lt-active="false"`.
  * Added `dark` option, and [provided CSS](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html#pre_css).

## 2.0.6 / 2022-04-11
  * Niggling little bug thing. Gone.

## 2.0.5 / 2022-04-11
  * Now using `Shellwords` and `KeyValueParser` instead of a homegrown parser.
  * Refactored helper methods to jekyll_tag_helper.rb
  * Looks up values for liquid variable references from several scopes.
  * Suppresses stack dump when an error occurs.
  * Deleted a lot of old cruft. Virtually none of the original code remains.
  * Added pre, label and copy_button optional parameters

## 2.0.4 / 2022-04-05
  * Updated to `jekyll_plugin_logger` v2.1.0

## 2.0.0 / 2022-03-11
  * Made into a Ruby gem and published on RubyGems.org as
    [jekyll_flexible_include](https://rubygems.org/gems/jekyll_flexible_include).
  * `bin/attach` script added for debugging.
  * Rubocop standards added.
  * Proper versioning and CHANGELOG.md added.

## 1.1.1 / 2021-05-01
  * Handles spaces in filenames properly.

## 1.1.0 / 2020-04-27
  * Added `do_not_escape` optional parameter.

## 1.0.0 / 2020-11-28
  * Mike Slinn took over the project.
  * Now supports relative includes.

## 2020-11-28
  * Mike Slinn renamed `include_absolute` to `flexible_include`.

## 2020-08-23
  * Now supports absolute paths.

## 2022-03-11
  * Project began.
