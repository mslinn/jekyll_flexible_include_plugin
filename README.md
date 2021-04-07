![Release](https://img.shields.io/badge/1.1.0-Release-blue)
![License](https://img.shields.io/badge/license-MIT-green)

# Jekyll `flexible_include` Tag Plugin

Originally called  `include_absolute`, this plugin's has been renamed to `flexible_include` because it no longer just includes absolute file names.

## Purpose

Jekyll's built-in `include` tag does not support including files outside of the `_includes` folder.
This plugin supports 4 types of includes.

### Include Types

1. Absolute filenames (start with `/`).
2. Filenames relative to the top-level directory of the Jekyll web site (Do not preface with `.` or `/`).
3. Filenames relative to the user home directory (preface with `~`).
4. Executable filenames on the `PATH` (preface with `!`).

In addition, filenames that require environment expansion because they contain a <code>$</code> character are
expanded according to the environment variables defined when <code>jekyll build</code> executes.

### Syntax:
```
{% flexible_include path [ do_not_escape='true' ] %}
```

The included file will escape characters <code>&lt;</code>, <code>{</code> and <code>}</code> unless <code>do_not_escape</code>
is specified with a value other than <code>false</code>.

### Installation

Copy `flexible_include.rb` into `/_plugins` and restart Jekyll.

### Examples

1. Include a file without parameters.
   ```
   {% flexible_include '../../folder/outside/jekyll/site/foo.html' %}
   {% flexible_include 'folder/within/jekyll/site/bar.js' %}
   {% flexible_include '/etc/passwd' %}
   {% flexible_include '~/.ssh/config' %}
   {% flexible_include '!jekyll' %}
   {% flexible_include '$HOME/.bash_aliases' %}
   ```

2. Include a JSON file (without escaping characters).
   ```
   {% flexible_include '~/folder/under/home/directory/foo.html' do_not_escape='true' %}
   ```

## Implementation

The top-level directory of the Jekyll web site is known as the "source folder".

### Revision History

 1.1.0 Added `do_not_escape` optional parameter

 1.0.0 First official release

### TODO

The `validate_file_name` call is commented out because mslinn did not have time
to figure out how to modify it so that filenames relative to the home directory would work.


## License

[MIT](./LICENSE)
