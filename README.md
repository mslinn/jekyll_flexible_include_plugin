# Jekyll `flexible_include` Tag Plugin

Originally called  `include_absolute`, this plugin's has been renamed to `flexible_include` because it no longer just includes absolute file names.

Jekyll's built-in `include` tag does not support including files outside of the `_includes` folder.
This plugin supports 4 types of includes:

1. Absolute filenames (start with `/`).
2. Filenames relative to the top-level directory of the Jekyll web site (Do not preface with `.` or `/`).
3. Filenames relative to the user home directory (preface with `~`).
4. Executable filenames on the `PATH` (preface with `!`).

### Syntax:
```
{% flexible_include path [ optionalParam1='yes' optionalParam2='green' ] %}
```

The optional parameters can have any name.
The included file will have parameters substituted.

### Installation

Copy `flexible_include.rb` into `/_plugins` and restart Jekyll.

### Examples

1. Include files without parameters; all four types of includes are shown.
   ```
   {% flexible_include '../../folder/outside/jekyll/site/foo.html' %}
   {% flexible_include 'folder/within/jekyll/site/bar.js' %}
   {% flexible_include '/etc/passwd' %}
   {% flexible_include '~/.ssh/config' %}
   ```

2. Include a file and pass parameters to it.
   ```
   {% flexible_include '~/folder/under/home/directory/foo.html' param1='yes' param2='green' %}
   ```

 ## Implementation

 The top-level directory of the Jekyll web site is known as the "source folder".

 ### TODO

 The `validate_file_name` call is commented out because mslinn did not have time
 to figure out how to modify it so that filenames relative to the home directory would work.


## License

[MIT](./LICENSE)
