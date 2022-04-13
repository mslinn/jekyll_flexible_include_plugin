# frozen_string_literal: true

require "jekyll"
require "jekyll_plugin_logger"
require "shellwords"
require_relative "flexible_include/version"

module JekyllFlexibleIncludeName
  PLUGIN_NAME = "flexible_include"
end

class FlexibleInclude < Liquid::Tag
  # @param tag_name [String] the name of the tag, which we already know.
  # @param markup [String] the arguments from the tag, as a single string.
  # @param _parse_context [Liquid::ParseContext] hash that stores Liquid options.
  #        By default it has two keys: :locale and :line_numbers, the first is a Liquid::I18n object, and the second,
  #        a boolean parameter that determines if error messages should display the line number the error occurred.
  #        This argument is used mostly to display localized error messages on Liquid built-in Tags and Filters.
  #        See https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers#create-your-own-tags
  def initialize(tag_name, markup, parse_context)
    super
    @logger = PluginMetaLogger.instance.new_logger(self, PluginMetaLogger.instance.config)
    @argv = Shellwords.split(markup)
    @params = KeyValueParser.new.parse(@argv) # Returns Hash[Symbol, String|Boolean]
    @logger.debug { "@params='#{@params}'" }
  end

  # @param context [Liquid::Context]
  def render(liquid_context) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @liquid_context = liquid_context
    @page = liquid_context.registers[:page]

    # markup = remove_enclosing_quotes(markup)
    @params = @params.map { |k, _v| lookup_variable(k) }
    if @params.include? "do_not_escape"
      @do_not_escape = true
      @params.delete("do_not_escape")
      @argv.delete("do_not_escape")
    end

    filename = @params.first
    @logger.debug("filename=#{filename}")

    path = expand_env(filename)
    case path
    when /\A\// # Absolute path
      @logger.debug { "Absolute path=#{path}, filename=#{filename}" }
    when /\A~/ # Relative path to user's home directory
      @logger.debug { "Relative start filename=#{filename}, path=#{path}" }
      filename.slice! "~/"
      path = File.join(ENV['HOME'], filename)
      @logger.debug { "Relative end filename=#{filename}, path=#{path}" }
    when /\A!/ # Run command and return response
      filename = remove_quotes(@argv.first)
      filename.slice! "!"
      @logger.debug { "Execute filename=#{filename}" }
      contents = run(filename)
    else # Relative path
      site = @liquid_context.registers[:site]
      source = File.expand_path(site.config['source']) # website root directory
      path = File.join(source, filename) # Fully qualified path of include file from relative path
      @logger.debug { "Catchall end filename=#{filename}, path=#{path}" }
    end
    render_completion(@liquid_context, path, contents)
  end

  private

  def dereference_variable(name)
    @liquid_context[name] || @page[name] || name
  end

  # Expend environment variable references
  def expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV[$1] }
  end

  def escape_html(string)
    string.gsub("{", "&#123;").gsub("}", "&#125;").gsub("<", "&lt;")
  end

  def lookup_variable(symbol)
    string = symbol.to_s
    return string unless string.start_with?("{{") && string.end_with?("}}")

    dereference_variable(string.delete_prefix("{{").delete_suffix("}}"))
  end

  def read_file(file)
    File.read(file)
  end

  def realpath_prefixed_with?(path, dir)
    File.exist?(path) && File.realpath(path).start_with?(dir)
  rescue StandardError
    false
  end

  # strip leading and trailing quotes if present
  def remove_quotes(string)
    string.strip.gsub(/\A'|'\Z/, '').strip if string
  end

  def render_completion(context, path, contents) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    begin
      contents ||= read_file(path)
    rescue StandardError => e
      puts "flexible_include.rb error: #{e.message}".red
      $stderr.reopen(IO::NULL)
      $stdout.reopen(IO::NULL)
      exit
    end
    escaped_contents = @do_not_escape ? contents : escape_html(contents)
    context.stack do # Temporarily push a new local scope onto the variable stack
      begin
        partial = Liquid::Template.parse(escaped_contents) # Type Liquid::Template
      rescue StandardError => e
        puts "flexible_include.rb error: #{e.message}".red
        $stderr.reopen(IO::NULL)
        $stdout.reopen(IO::NULL)
        exit
      end

      begin
        partial.render!(context)
      rescue Liquid::Error => e
        e.template_name = path
        e.markup_context = "included " if e.markup_context.nil?
        raise e
      end
    end
  end

  def run(cmd)
    %x[#{cmd}].chomp
  end
end

PluginMetaLogger.instance.info { "Loaded #{JekyllFlexibleIncludeName::PLUGIN_NAME} v#{JekyllFlexibleIncludePluginVersion::VERSION} plugin." }
Liquid::Template.register_tag('flexible_include', FlexibleInclude)
