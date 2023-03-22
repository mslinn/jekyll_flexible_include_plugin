Jekyll `flexible_include` Plugin
[![Gem Version](https://badge.fury.io/rb/jekyll_flexible_include.svg)](https://badge.fury.io/rb/jekyll_flexible_include)
===========

`Flexible_include` is a Jekyll plugin that includes the contents of a file
or the result of a process into a generated page.
`Flexible_include` is useful because Jekyll's built-in `include` tag only
supports the including of files residing within the `_includes/` subfolder of a Jekyll project,
and because `flexible_include` offers additional ways of including content.

Originally called  `include_absolute`,
this plugin has been renamed to `flexible_include` because it no longer just
includes absolute file names.

This plugin is available as a [Ruby gem](https://rubygems.org/gems/jekyll_flexible_include).
More information is available on my website about [my Jekyll plugins](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html).

This plugin supports 4 types of includes:


### Include Types

1. Absolute filenames (recognized by filename paths that start with `/`).

2. Filenames relative to the top-level directory of the Jekyll website (relative paths **do not** start with `.` or `/`).

3. Filenames relative to the user home directory (recognized by filename paths starting with `~/`).

4. Executable filenames on the `PATH` (recognized by filename paths that begin with `!`).


In addition, filenames that require environment expansion because they contain a
<code>$</code> character are expanded according to the environment variables
defined when <code>jekyll build</code> executes.


A file from a git repository can also be included.
Files can be retrieved from at a given commit or tag.
Two new options are provided for this purpose:
  - `repo` - directory where git repo resides; environment variables are expanded; defaults to current directory.
  - `git_ref` - Git ref of commit or tag to be examined for the file; defaults to `HEAD`.


### Configuration
Configuration parameters can be added to a section in `_config.yml` called `flexible_include`, like this:

```yaml
flexible_include:
  die_on_file_error: true
  die_on_path_denied: true
  die_on_run_error: true
  die_on_other_error: true
```

The default values for all of these parameters is `false`,
except for `die_on_other_error`, which defaults to `true`.

 - If `die_on_file_error` is enabled, then an attempt to include a file that fails will cause Jekyll to die with an error message.

 - If `die_on_path_denied` is enabled (see [Restricting Directory Access](#restricting-directory-access)), then an attempt to include a file that should be blocked will cause Jekyll to die with an error message.

 - If `die_on_run_error` is enabled, then an attempt to run a process that fails will cause Jekyll to die with an error message.

 - If `die_on_other_error` is enabled, then any other exception will cause Jekyll to die with an error message.


### Syntax
The following are all equivalent, however, the first two are recommended:
```html
{% flexible_include file="path" [ OPTIONS ] %}
{% flexible_include file='path' [ OPTIONS ] %}
{% flexible_include path [ OPTIONS ] %}
{% flexible_include 'path' [ OPTIONS ] %}
{% flexible_include "path" [ OPTIONS ] %}
```

Note that the [square brackets] merely indicate optional parameters
and are not intended to be written literally.


### Options
  * `do_not_escape` keyword option caused the content to be included without HTML escaping it.
    By default, the included file will escape characters <code>&lt;</code>,
    <code>{</code> and <code>}</code> unless the <code>do_not_escape</code> keyword option is specified.

  * `highlight='regex pattern here'` wraps content matching the regex pattern within a
    `<span class='bg_yellow'></span>` tag.
    Note that the pattern can simply consist of the exact text that you want to highlight.

  * `pre` is a keyword option that causes the included file to be wrapped inside a
    &lt;pre>&lt;/pre> tag; no label is generated.
    The &lt;pre>&lt;/pre> tag has an `data-lt-active="false"` attribute, so
    [LanguageTool](https://forum.languagetool.org/t/avoid-spell-check-on-certain-html-inputs-manually/3944)
    will not attempt to check the spelling or grammar of the contents.

The following options imply `pre`:
  * `dark` keyword option applies the `dark` class to the generated &lt;pre>&lt;/pre> tag.
    You can define the `dark` and `darkLabel` classes as desired.
    [This CSS is a good starting point.](https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html#pre_css)

  * `download` keyword option uses the name of the file as a label,
    and displays it above the &lt;pre>&lt;/pre> tag.
    Clicking the label causes the file to be downloaded.

  * `copyButton` keyword option draws an icon at the top right of the &lt;pre>&lt;/pre>
    tag that causes the included contents to be copied to the clipboard.

  * `label` keyword option specifies that an automatically generated label be placed above the contents.
    There is no need to specify this option if `download` or `copy_button` options are provided.

  * `label="blah blah"` specifies a label for the contents; this value overrides the default label.
    The value can be enclosed in single or double quotes.


### Restricting Directory Access
By default, `flexible_include` can read from all directories according to the permissions of the user account that launched the `jekyll` process.
For security-conscience environments, the accessible paths can be restricted.

Defining an environment variable called `FLEXIBLE_INCLUDE_PATHS` prior to launching Jekyll will restrict the paths that `flexible_include` will be able to read from.
This environment variable consists of a colon-delimited set of
[file and directory glob patterns](https://docs.ruby-lang.org/en/2.7.0/Dir.html#method-c-glob).
For example, the following restricts access to only the files within:

 1. The `~/my_dir` directory tree of the account of the user that launched Jekyll.

 2. The directory tree rooted at `/var/files`.

 3. The directory tree rooted at the expanded value of the `$work` environment variable.

```shell
export FLEXIBLE_INCLUDE_PATHS='~/.*:$sites/.*:$work/.*'
```

Note that the above matches dot (hidden) files as well as regular files.
To just match visible files:

```shell
export FLEXIBLE_INCLUDE_PATHS='~/my_dir/**/*:/var/files/**/*:$work/**/*'
```

#### Note
The specified directories are traversed when the plugin starts,
and the filenames are stored in memory.
Directories with lots of files might take a noticable amount of
time to enumerate the files.


### Restricting Arbitrary Processes
By default, `flexible_include` can execute any command.
You can disable that by setting the environment variable `DISABLE_FLEXIBLE_INCLUDE`
to any non-empty value.
```shell
export DISABLE_FLEXIBLE_INCLUDE=true
```

If a potential command execution is intercepted,
a big red message will appear on the generated web page that says
`Arbitrary command execution denied by DISABLE_FLEXIBLE_INCLUDE value.`,
and a red error message will be logged on the console that says something like:
`ERROR FlexibleInclude: _posts/2020/2020-10-03-jekyll-plugins.html - Arbitrary command execution denied by DISABLE_FLEXIBLE_INCLUDE value.`


## Installation
1. Add the following to `Gemfile`, inside the `jekyll_plugins` group:
   ```ruby
   group :jekyll_plugins do
     gem 'jekyll_flexible_include', '~> 2.0.15'
   end
   ```

2. Add the following to `_config.yml`.
   This is necessary because the name of the plugin
   does not match the name of the entry point file:
   ```yaml
   plugins:
     - flexible_include
   ```

3. Copy `demo/assets/images/clippy.svg` to a directory that resolves to
   `assets/images/` in your Jekyll website.

4. Copy the CSS from `demo/assets/css/styles.css` between the comments to your Jekyll project's CSS file:
   ```css
   blah blah blah

   /* START OF CSS TO COPY */
   Copy this stuff
   /* END OF CSS TO COPY */

   blah blah blah
   ```

5. Install the `jekyll_flexible_include` Ruby gem as usual:
   ```shell
   $ bundle install
   ```


## Examples

1. Include files, escaping any HTML markup, so it appears as written; all four types of includes are shown.
   ```
   {% flexible_include '../../folder/outside/jekyll/site/foo.html' %}
   {% flexible_include 'folder/within/jekyll/site/bar.js' %}
   {% flexible_include '/etc/passwd' %}
   {% flexible_include '~/.ssh/config' %}
   {% flexible_include '!jekyll help' %}
   {% flexible_include '$HOME/.bash_aliases' %}
   ```

2. Include a JSON file (without escaping characters).
   ```
   {% flexible_include do_not_escape file='~/folder/under/home/directory/foo.html' %}
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

1. Ensure `_config.yml` doesn't have `safe: true` set.
   That prevents all plugins from working.

2. If you have version older than v2.x.x,
   delete the file `_plugins/flexible_include.rb`,
   or you will have version conflicts.


## Development
After checking out the repo, run `bin/setup` to install dependencies as binstubs in the `exe` directory.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Build and Install Locally
To build and install this gem onto your local machine, run:
```shell
$ rake install
```

Examine the newly built gem:
```shell
$ gem info jekyll_flexible_include

*** LOCAL GEMS ***

jekyll_flexible_include (2.0.4)
    Authors: Mike Slinn, Tan Nhu, Maarten Brakkee
    Homepage: https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html#flexibleInclude
    License: MIT
    Installed at (2.0.4): /home/mslinn/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0

    Jekyll plugin supports various ways to include content into the
    generated site.
```


## Demo Website
A test/demo website is provided in the `demo` directory.
You can run it under a debugger, or let it run free.

The `demo/_bin/debug` script can set various parameters for the demo.
View the help information with the `-h` option:
```shell
$ demo/_bin/debug -h

debug - Run the demo Jekyll website.

By default the demo Jekyll website runs without restriction under ruby-debug-ide and debase.
View it at http://localhost:4444

Options:
  -e  Restrict the allowable directories to read from to the following regexes:
        jekyll_flexible_include_plugin/.*
        /dev/.*
        /proc/.*
        /run/.*

  -h  Show this error message

  -r  Run freely, without a debugger

  -x  Disable the ability to execute arbitrary commands
```


### Debugging the Demo
To run under a debugger, for example Visual Studio Code:
 1. Set breakpoints.

 2. Initiate a debug session from the command line:
    ```shell
    $ demo/bin/debug
    ```

  3. Once the `Fast Debugger` signon appears, launch the Visual Studio Code launch configuration called `Attach rdebug-ide`.

  4. View the generated website at [`http://localhost:4444`](http://localhost:4444).


### Build and Push to RubyGems
To release a new version,

  1. Update the version number in `version.rb`.

  2. Add a comment to the top of `CHANGELOG.md`.

  3. Commit all changes to git; if you don't the next step will fail.

  4. Run the following:
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
