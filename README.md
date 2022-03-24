Jekyll `flexible_include` Plugin
[![Gem Version](https://badge.fury.io/rb/jekyll_flexible_include.svg)](https://badge.fury.io/rb/jekyll_flexible_include)
===========

`Flexible_include` is a Jekyll plugin that includes the contents of a file or the result of a process into a generated page. `Flexible_include` is useful because Jekyll's built-in `include` tag only supports the including of files residing within the `_includes/` subfolder of a Jekyll project, and because `flexible_include` offers additional ways of including content.

Originally called  `include_absolute`, this plugin has been renamed to `flexible_include` because it no longer just includes absolute file names.

This plugin is available as a [Ruby gem](https://rubygems.org/gems/jekyll_flexible_include).
More information is available on my website about [my Jekyll plugins](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html).

This plugin supports 4 types of includes:

### Include Types

1. Absolute filenames (recognized by filename paths that start with `/`).
2. Filenames relative to the top-level directory of the Jekyll web site (relative paths **do not** start with `.` or `/`).
3. Filenames relative to the user home directory (recognized by filename paths starting with `~/`).
4. Executable filenames on the `PATH` (recognized by filename paths that begin with `!`).


In addition, filenames that require environment expansion because they contain a <code>$</code> character are
expanded according to the environment variables defined when <code>jekyll build</code> executes.

### Syntax:
```
{% flexible_include path [ do_not_escape='true' ] %}
```

The included file will escape characters <code>&lt;</code>, <code>{</code> and <code>}</code> unless <code>do_not_escape</code>
is specified with a value other than <code>false</code>.
Note that the [square brackets] merely indicate an optional parameter and are not intended to be literally written.


### Additional Information
More information is available on my web site about [my Jekyll plugins](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html).


## Installation

Add the following to `Gemfile`, inside the `jekyll_plugins` group:
```
group :jekyll_plugins do
  gem 'jekyll_flexible_include', '~> 2.0.0'
end
```

Also add it to `_config.yml`:
```yaml
plugins:
  - flexible_include
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install jekyll_flexible_include


## Examples

1. Include files without parameters; all four types of includes are shown.
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

## Additional Information
More information is available on
[Mike Slinn&rsquo;s website](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html).


## GitHub Pages
GitHub Pages only allows [these plugins](https://pages.github.com/versions/).
That means `flexible_include` will not work on GitHub Pages.
Following is a workaround.
1. Let's assume your git repository that you want to publish as GitHub Pages is called `mysite`.
   This repository cannot be the source of your GitHub Pages because you are using the `flexible_include` plugin.
2. Make a new git repository to hold the generated website. Let's call this git repository `generated_site`.
3. Generate `mysite` locally as usual.
4. Copy the generated HTML in the `mysite/_site/` directory to `generated_site`.
5. Run `git commit` on `generated_site`.
6. Tell GitHub that you want the `generated_site` repository to hold your GitHub pages.
7. A moment later, your website will now be visible as GitHub Pages, with the included content, just as you saw it locally.


## Known Issues
If the plugin does not work:
1. Ensure `_config.yml` doesn't have `safe: true`. That prevents all plugins from working.
2. If you have version older than v2.x.x, delete the file `_plugins/flexible_include.rb` or you will have version conflicts.


## Development

After checking out the repo, run `bin/setup` to install dependencies.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Build and Install Locally
To build and install this gem onto your local machine, run:
```shell
$ rake install:local
```

The following also does the same thing:
```shell
$ bundle exec rake install
```

Examine the newly built gem:
```shell
$ gem info jekyll_flexible_include

*** LOCAL GEMS ***

jekyll_flexible_include (1.0.0)
    Author: Mike Slinn
    Homepage:
    https://github.com/mslinn/jekyll_flexible_include
    License: MIT
    Installed at: /home/mslinn/.gems

    Generates Jekyll logger with colored output.
```


### Build and Push to RubyGems
To release a new version,
  1. Update the version number in `version.rb`.
  2. Commit all changes to git; if you don't the next step might fail with an unexplainable error message.
  3. Run the following:
     ```shell
     $ bundle exec rake release
     ```
     The above creates a git tag for the version, commits the created tag,
     and pushes the new `.gem` file to [RubyGems.org](https://rubygems.org).


## Contributing

1. Fork the project
2. Create a descriptively named feature branch
3. Add your feature
4. Submit a pull request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
