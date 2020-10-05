# Jekyll `flexible_include` Tag

A Jekyll's liquid tag plugin to include a file from its path relative to Jekyll's source folder. Why? Because Jekyll's built-in `include` tag does not support including files outside of the `_includes` folder.

Syntax: `{% flexible_include path %}`

## Installation

Copy `flexible_include.rb` into `/_plugins`.

## Examples

With this plugin you can include only a file.
```
{% flexible_include '../../folder/outside/jekyll/foo.html' %}
{% flexible_include 'other/folder/bar.js' %}
```
Or include the file and pass parameters to it.
```
{% flexible_include '../../folder/outside/jekyll/foo.html' param1='yes' param2='green' %}
```

## License

[MIT](./LICENSE)
