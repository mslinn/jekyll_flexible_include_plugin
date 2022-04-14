# frozen_string_literal: true

require "jekyll"
require "jekyll_plugin_logger"
require "securerandom"
require_relative "flexible_include/version"
require_relative "jekyll_tag_helper"

module JekyllFlexibleIncludeName
  PLUGIN_NAME = "flexible_include"
end

class FlexibleInclude < Liquid::Tag
  FlexibleIncludeError = Class.new(Liquid::Error)

  # @param tag_name [String] the name of the tag, which we already know.
  # @param markup [String] the arguments from the tag, as a single string.
  # @param parse_context [Liquid::ParseContext] hash that stores Liquid options.
  #        By default it has two keys: :locale and :line_numbers, the first is a Liquid::I18n object, and the second,
  #        a boolean parameter that determines if error messages should display the line number the error occurred.
  #        This argument is used mostly to display localized error messages on Liquid built-in Tags and Filters.
  #        See https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers#create-your-own-tags
  def initialize(tag_name, markup, _parse_context)
    super
    @logger = PluginMetaLogger.instance.new_logger(self, PluginMetaLogger.instance.config)
    @helper = JekyllTagHelper.new(tag_name, markup, @logger)
  end

  # @param liquid_context [Liquid::Context]
  def render(liquid_context) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/CyclomaticComplexity
    @helper.liquid_context = liquid_context
    @do_not_escape = @helper.parameter_specified? "do_not_escape"
    @download = @helper.parameter_specified? "download"
    @label = @helper.parameter_specified? "label"
    @label_specified = @label
    @copy_button = @helper.parameter_specified? "copyButton"
    @pre = @copy_button || @download || @label_specified || @helper.parameter_specified?("pre") # Download or label implies pre
    filename = @helper.parameter_specified? "file"
    filename ||= @helper.params.first # Do this after all options have been checked for
    @label ||= filename

    # If a label was specified, use it, otherwise concatenate any dangling parameters and use that as the label
    @label ||= @helper.params[1..].join(" ")

    @logger.debug("filename=#{filename}")

    path = JekyllTagHelper.expand_env(filename)
    case path
    when /\A\// # Absolute path
      @logger.debug { "Absolute path=#{path}, filename=#{filename}" }
    when /\A~/ # Relative path to user's home directory
      @logger.debug { "User home start filename=#{filename}, path=#{path}" }
      filename.slice! "~/"
      path = File.join(ENV['HOME'], filename)
      @logger.debug { "User home end filename=#{filename}, path=#{path}" }
    when /\A!/ # Run command and return response
      filename = JekyllTagHelper.remove_quotes(@helper.argv.first) if @helper.argv.first
      filename.slice! "!"
      contents = run(filename)
    else # Relative path
      site = liquid_context.registers[:site]
      source = File.expand_path(site.config['source']) # website root directory
      path = File.join(source, filename) # Fully qualified path of include file from relative path
      @relative = true
      @logger.debug { "Relative end filename=#{filename}, path=#{path}" }
    end
    render_completion(path, contents)
    # rescue StandardError => e
    #   raise FlexibleIncludeError, e.message.red, [] # Suppress stack trace
  end

  private

  def read_file(file)
    File.read(file)
  end

  def realpath_prefixed_with?(path, dir)
    File.exist?(path) && File.realpath(path).start_with?(dir)
  rescue StandardError
    false
  end

  def render_completion(path, contents)
    contents ||= read_file(path)
    contents2 = @do_not_escape ? contents : JekyllTagHelper.escape_html(contents)
    @pre ? wrap_in_pre(path, contents2) : contents2
  end

  def run(cmd)
    @logger.debug { "Executing filename=#{cmd}" }
    %x[#{cmd}].chomp
  end

  PREFIX = "<button class='copyBtn' data-clipboard-target="
  SUFFIX = "title='Copy to clipboard'><img src='/assets/images/clippy.svg' alt='Copy to clipboard' style='width: 13px'></button>"

  def wrap_in_pre(path, content)
    basename = File.basename(path)
    label_or_href = if @download
                      label = @label_specified ? @label : basename
                      <<~END_HREF
                        <a href='data:text/plain;charset=UTF-8,#{basename}' download='#{basename}'
                          title='Click on the file name to download the file'>#{label}</a>
                      END_HREF
                    else
                      @label_specified ? @label : basename
                    end
    pre_id = "id#{SecureRandom.hex 6}"
    copy_button = @copy_button ? "#{PREFIX}'##{pre_id}'#{SUFFIX}" : ""
    <<~END_PRE
      <div class="codeLabel">#{label_or_href}</div>
      <pre data-lt-active="false" class="maxOneScreenHigh copyContainer" id="#{pre_id}">#{copy_button}#{content}</pre>
    END_PRE
  end
end

PluginMetaLogger.instance.info { "Loaded #{JekyllFlexibleIncludeName::PLUGIN_NAME} v#{JekyllFlexibleIncludePluginVersion::VERSION} plugin." }
Liquid::Template.register_tag('flexible_include', FlexibleInclude)
