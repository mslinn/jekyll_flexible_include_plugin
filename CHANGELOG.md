## 2.0.5 / 2022-04-11
  * Now using <code>Shellwords</code> and <code>KeyValueParser</code> instead of a homegrown parser.
  * Refactored helper methods to jekyll_tag_helper.rb
  * Looks up values for liquid variable references from several scopes.
  * Suppresses stack dump when an error occurs.
  * Deleted a lot of old cruft.
  * Added pre, label and copy_button optional parameters

## 2.0.4 / 2022-04-05
  * Updated to `jekyll_plugin_logger` v2.1.0

## 2.0.0 / 2022-03-11
  * Made into a Ruby gem and published on RubyGems.org as [jekyll_flexible_include](https://rubygems.org/gems/jekyll_flexible_include).
  * `bin/attach` script added for debugging
  * Rubocop standards added
  * Proper versioning and CHANGELOG.md added

## 1.1.1 / 2021-05-01
  * Handles spaces in filenames properly.

## 1.1.0 / 2020-04-27
  * Added `do_not_escape` optional parameter.

## 1.0.0 / 2020-11-28
  * Mike Slinn took over the project
  * Now supports relative includes

## 2020-11-28
  * Renamed include_absolute to flexible_include

## 2020-08-23
  * Now supports absolute paths

## 2022-03-11
  * Project began
