
require_relative "lib/flexible_include/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll_flexible_include"
  spec.version = JekyllFlexibleIncludePlugin::VERSION
  spec.authors = ["Mike Slinn"]
  spec.email = ["mslinn@mslinn.com"]

  spec.summary = "Jekyll plugin supports various ways to include content into the generated site."
  spec.description = <<~END_OF_DESC
    Jekyll's built-in include tag only supports including files within the _includes folder.
    This plugin supports 4 types of includes: absolute filenames,
    filenames relative to the top-level directory of the Jekyll web site,
    filenames relative to the user home directory,
    and executable filenames on the PATH.
  END_OF_DESC
  spec.homepage = "https://github.com/mslinn/jekyll_flexible_include_plugin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mslinn/jekyll_flexible_include_plugin"
  spec.metadata["changelog_uri"] = "https://github.com/mslinn/jekyll_flexible_include_plugin/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing jekyll_flexible_include!

  END_MESSAGE

  spec.add_dependency 'jekyll', '>= 3.5.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-jekyll'
end
