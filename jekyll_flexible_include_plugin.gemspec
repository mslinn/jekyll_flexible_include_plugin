# frozen_string_literal: true

require_relative "lib/flexible_include/version"

Gem::Specification.new do |spec|
  github = "https://github.com/mslinn/jekyll_flexible_include_plugin"

  spec.authors = ["Mike Slinn", "Tan Nhu", "Maarten Brakkee"]
  spec.bindir = "exe"
  spec.description = <<~END_OF_DESC
    Jekyll's built-in include tag only supports including files within the _includes folder.
    This plugin supports 4 types of includes: absolute filenames,
    filenames relative to the top-level directory of the Jekyll web site,
    filenames relative to the user home directory,
    and executable filenames on the PATH.
  END_OF_DESC
  spec.email = ["mslinn@mslinn.com"]
  spec.files = Dir[".rubocop.yml", "LICENSE.*", "Rakefile", "{lib,spec}/**/*", "*.gemspec", "*.md"]
  spec.homepage = "https://www.mslinn.com/blog/2020/10/03/jekyll-plugins.html#flexibleInclude"
  spec.license = "MIT"
  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri"   => "#{github}/issues",
    "changelog_uri"     => "#{github}/CHANGELOG.md",
    "homepage_uri"      => spec.homepage,
    "source_code_uri"   => github,
  }
  spec.name = "jekyll_flexible_include"
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.6.0"
  spec.summary = "Jekyll plugin supports various ways to include content into the generated site."
  spec.test_files = spec.files.grep(%r!^(test|spec|features)/!)
  spec.version = JekyllFlexibleIncludePluginVersion::VERSION

  spec.add_dependency "jekyll", ">= 3.5.0"
  spec.add_dependency "jekyll_plugin_logger", '~> 2.1.0'

  spec.add_development_dependency "debase"
  # spec.add_development_dependency "rubocop-jekyll"
  # spec.add_development_dependency "rubocop-rake"
  # spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "ruby-debug-ide"
end
