# frozen_string_literal: true

require "jekyll"
require "jekyll_plugin_logger"
require_relative "flexible_include/version"

module JekyllFlexibleIncludeName
  PLUGIN_NAME = "flexible_include"
end

class FlexibleIncludeError < StandardError
  attr_accessor :path

  def initialize(msg, path)
    super
    @path = path
  end
end

class FlexibleInclude < Liquid::Tag
  VALID_SYNTAX = %r!
    ([\w-]+)\s*=\s*
    (?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w.-]+))
  !x.freeze
  VARIABLE_SYNTAX = %r!
    (?<variable>[^{]*(\{\{\s*[\w\-.]+\s*(\|.*)?\}\}[^\s{}]*)+)
    (?<params>.*)
  !mx.freeze

  FULL_VALID_SYNTAX = %r!\A\s*(?:#{VALID_SYNTAX}(?=\s|\z)\s*)*\z!.freeze
  VALID_FILENAME_CHARS = %r!^[\w/\.-]+$!.freeze

  def initialize(tag_name, markup, parse_context)
    super
    @logger = PluginMetaLogger.instance.new_logger(self, PluginMetaLogger.instance.config)
    matched = markup.strip.match(VARIABLE_SYNTAX)
    if matched
      @file = matched["variable"].strip
      @params = matched["params"].strip
    else
      @file, @params = markup.strip.split(%r!\s+!, 2)
    end
    @markup = markup
    @logger.debug("initialize: @markup=#{@markup}")
    @parse_context = parse_context
  end

  # @param context [Liquid::Context]
  def render(context) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    markup = @markup
    @logger.debug { "markup='#{markup}'" }
    markup = sanitize_parameter(markup)
    markup = expand_env(markup)
    path = markup
    if /\A\//.match(markup)  # Is the file absolute?
      @logger.debug { "Absolute path=#{path}, markup=#{markup}" }
    elsif /\A~/.match(markup)  # Relative path to user's home directory?
      @logger.debug { "Relative start markup=#{markup}, path=#{path}" }
      markup.slice! "~/"
      path = File.join(ENV['HOME'], markup)
      @logger.debug { "Relative end markup=#{markup}, path=#{path}" }
    elsif /\A\!/.match(markup)  # Run command and return response
      markup.slice! "!"
      @logger.debug { "Execute markup=#{markup}" }
      contents = run(markup)
    else  # The file is relative or it was passed as a parameter to an include and was not noticed before, e.g. @file='{{include.file}}'
      @logger.debug { "Catchall start @file=#{@file}, markup=#{markup}, path=#{path}" }
      file = render_variable(context)
      markup = file if file
      markup = expand_env(markup)
      markup = sanitize_parameter(markup)
      if /\A\//.match(markup) # Absolute path
        path = markup
      elsif /\A\!/.match(markup)
        markup.slice! "!"
        @logger.debug { "Execute markup=#{markup}" }
        contents = run(markup)
      elsif /\A~/.match(markup)  # Relative path to user's home directory?
        markup.slice! "~/"
        path = File.join(ENV['HOME'], markup)
      else # Relative path
        site = context.registers[:site]
        source = File.expand_path(site.config['source']) # website root directory
        path = File.join(source, markup) # Fully qualified path of include file from relative path
      end
      @logger.debug { "Catchall end markup=#{markup}, path=#{path}" }
    end
    render_completion(context, path, contents)
  end

  private

  def escape_html?(context)
    do_not_escape = false
    if @params
      context["include"] = parse_params(context)
      @logger.debug { "context['include']['do_not_escape'] = #{context['include']['do_not_escape']}" }
      do_not_escape = context['include'].fetch('do_not_escape', 'false')
      @logger.debug { "do_not_escape=#{do_not_escape}" }
      @logger.debug { "do_not_escape=='false' = #{do_not_escape=='false'}" }
    end
    do_not_escape
  end

  def escape_html(string)
    string.gsub("{", "&#123;").gsub("}", "&#125;").gsub("<", "&lt;")
  end

  def expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV[$1] }
  end

  # Grab file read opts in the context
  def file_read_opts(context)
    context.registers[:site].file_read_opts
  end

  def parse_params(context)
    params = {}
    markup = @params

    while (match = VALID_SYNTAX.match(markup))
      markup = markup[match.end(0)..-1]

      value = if match[2]
                match[2].gsub(%r!\\"!, '"')
              elsif match[3]
                match[3].gsub(%r!\\'!, "'")
              elsif match[4]
                context[match[4]]
              end

      params[match[1]] = value
    end
    params
  end

  def read_file(file)
    File.read(file)
  end

  def realpath_prefixed_with?(path, dir)
    File.exist?(path) && File.realpath(path).start_with?(dir)
  rescue StandardError
    false
  end

  def render_completion(context, path, contents)
    begin
      contents = read_file(path) unless contents
    rescue StandardError => e
      puts "flexible_include.rb error: #{e.message}".red
      $stderr.reopen(IO::NULL)
      $stdout.reopen(IO::NULL)
      exit
    end
    escaped_contents = escape_html?(context) ? escape_html(contents) : contents
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

  # @return setvalue of 'file' variable if defined
  def render_variable(context)
    if @file.match VARIABLE_SYNTAX
      partial = context.registers[:site]
        .liquid_renderer
        .file("(variable)")
        .parse(@file)
      partial.render!(context)
    end
  end

  def run(cmd)
    %x[ #{cmd} ].chomp
  end

  # strip leading and trailing quotes if present
  def sanitize_parameter(parameter)
    parameter.strip.gsub(/\A'|'\Z/, '').strip if parameter
  end

  def valid_include_file?(path, dir, safe)
    !outside_site_source?(path, dir, safe) && File.file?(path)
  end

  def outside_site_source?(path, dir, safe)
    safe && !realpath_prefixed_with?(path, dir)
  end

  def could_not_locate_message(file, includes_dirs, safe)
    message = "Could not locate the included file '#{file}' in any of "\
              "#{includes_dirs}. Ensure it exists in one of those directories and"
    message + if safe
                " is not a symlink as those are not allowed in safe mode."
              else
                ", if it is a symlink, does not point outside your site source."
              end
  end
end

PluginMetaLogger.instance.info { "Loaded #{JekyllFlexibleIncludeName::PLUGIN_NAME} v#{JekyllFlexibleIncludePluginVersion::VERSION} plugin." }
Liquid::Template.register_tag('flexible_include', FlexibleInclude)
