require 'benchmark'
require 'jekyll_plugin_support'
require 'securerandom'
require_relative 'flexible_include/version'

module JekyllFlexibleIncludeName
  PLUGIN_NAME = 'flexible_include'.freeze
end

module FlexibleClassMethods
  def access_allowed(path)
    return true unless @read_regexes

    @read_regexes.find { |regex| regex.match(normalize_path(path)) }
  end

  def self.escape_html(string)
    string.gsub("&", "&amp;")
          .gsub("{", "&#123;")
          .gsub("}", "&#125;")
          .gsub("<", "&lt;")
  end

  def normalize_path(path)
    JekyllPluginHelper.expand_env(path, die_if_undefined: true)
                      .gsub('~', Dir.home)
  end

  def number_content(content)
    lines = content.split("\n")
    digits = lines.length.to_s.length
    i = 0
    numbered_content = lines.map do |line|
      i += 1
      number = i.to_s.rjust(digits, ' ')
      "<span class='unselectable numbered_line'> #{number}: </span>#{line}"
    end
    result = numbered_content.join "\n"
    result += "\n" unless result.end_with? "\n"
    result
  end

  # If FLEXIBLE_INCLUDE_PATHS='~/lib/.*:.*:$WORK/.*'
  # Then @read_regexes will be set to regexes of ['/home/my_user_id/lib/.*', '/pwd/.*', '/work/envar/path/.*']
  def security_check
    @execution_denied = ENV.fetch('DISABLE_FLEXIBLE_INCLUDE', nil)

    return if @read_regexes

    flexible_include_paths = ENV.fetch('FLEXIBLE_INCLUDE_PATHS', nil)
    read_paths = normalize_path(flexible_include_paths) if flexible_include_paths
    return unless read_paths

    @read_regexes = read_paths.split(':').map do |path|
      abs_path = path.start_with?('/') ? path : (Pathname.new(Dir.pwd) + path).to_s
      Regexp.new(abs_path)
    end
  end
end

class FlexibleError < StandardError; end

class FlexibleInclude < JekyllSupport::JekyllTag
  include JekyllFlexibleIncludePluginVersion

  class << self
    include FlexibleClassMethods
  end

  FlexibleIncludeError = Class.new(Liquid::Error)

  def render_impl
    self.class.security_check
    parse_args
    path = JekyllPluginHelper.expand_env(@filename)

    case path
    when /\A\// # Absolute path
      return denied("Access to #{path} denied by FLEXIBLE_INCLUDE_PATHS value.") unless self.class.access_allowed(path)

      @logger.debug { "Absolute path=#{path}, @filename=#{@filename}" }
    when /\A~/ # Relative path to user's home directory
      return denied("Access to #{path} denied by FLEXIBLE_INCLUDE_PATHS value.") unless self.class.access_allowed(path)

      @logger.debug { "User home start @filename=#{@filename}, path=#{path}" }
      @filename = @filename.delete_prefix '~/'
      path = File.join(Dir.home, @filename)
      @logger.debug { "User home end @filename=#{@filename}, path=#{path}" }
    when /\A!/ # Run command and return response
      return denied('Arbitrary command execution denied by DISABLE_FLEXIBLE_INCLUDE value.') if @execution_denied

      @filename = JekyllPluginHelper.remove_quotes(@helper.argv.first) if @helper.argv.first
      @filename = @filename.delete_prefix '!'
      contents = run(@filename)
    else # Relative path
      source = File.expand_path(@site.config['source']) # website root directory
      path = File.join(source, @filename) # Fully qualified path of include file from relative path
      @relative = true
      @logger.debug { "Relative end @filename=#{@filename}, path=#{path}" }
    end
    render_completion(path, contents)
    # rescue StandardError => e
    #   raise FlexibleIncludeError, e.message.red, [] # Suppress stack trace
  end

  private

  def parse_args
    @do_not_escape = @helper.parameter_specified? 'do_not_escape'
    @download = @helper.parameter_specified? 'download'
    @dark = ' dark' if @helper.parameter_specified?('dark')
    @highlight_pattern = @helper.parameter_specified? 'highlight'
    @label = @helper.parameter_specified? 'label'
    @number_lines = @helper.parameter_specified? 'number'
    @label_specified = @label
    @copy_button = @helper.parameter_specified? 'copyButton'
    # Download, dark, label or number implies pre
    @pre = @helper.parameter_specified?('pre') || @copy_button || @dark || @download || @label_specified || @number_lines

    @filename = @helper.parameter_specified? 'file'
    @filename ||= @helper.params.first # Do this after all options have been checked for
    @label ||= @filename

    # If a label was specified, use it, otherwise concatenate any dangling parameters and use that as the label
    @label ||= @helper.params[1..].join(' ')

    @logger.debug("@filename=#{@filename}")
  end

  def denied(msg)
    @logger.error("#{@helper.page.path} - #{msg}")
    "<p style='color: white; background-color: red; padding: 2pt 1em 2pt 1em;'>#{msg}</p>"
  end

  def highlight(content, pattern)
    content.gsub(Regexp::new(pattern), "<span class='bg_yellow'>\\0</span>")
  end

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
    contents2 = @do_not_escape ? contents : FlexibleClassMethods.escape_html(contents)
    contents2 = highlight(contents2, @highlight_pattern) if @highlight_pattern
    contents2 = FlexibleInclude.number_content(contents2) if @number_lines
    @pre ? wrap_in_pre(path, contents2) : contents2
  end

  def run(cmd)
    @logger.debug { "Executing @filename=#{cmd}" }
    %x[#{cmd}].chomp
  end

  PREFIX = "<button class='copyBtn' data-clipboard-target=".freeze
  SUFFIX = "title='Copy to clipboard'><img src='/assets/images/clippy.svg' alt='Copy to clipboard' style='width: 13px'></button>".freeze

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
    copy_button = @copy_button ? "#{PREFIX}'##{pre_id}'#{SUFFIX}" : ''
    dark_label = ' darkLabel' if @dark
    <<~END_PRE
      <div class="codeLabel#{dark_label}">#{label_or_href}</div>
      <pre data-lt-active="false" class="maxOneScreenHigh copyContainer#{@dark}" id="#{pre_id}">#{copy_button}#{content}</pre>
    END_PRE
  end

  JekyllPluginHelper.register(self, 'flexible_include')
end
