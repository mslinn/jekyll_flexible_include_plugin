require 'pathname'
require 'English'
require 'facets/string/camelcase'
require 'facets/string/snakecase'
require 'jekyll_from_to_until'

module FlexibleInclude
  module FlexiblePrivateMethods
    include FromToUntil

    def denied(msg)
      msg_no_html = remove_html_tags(msg)
      @logger.error { "#{@page['path']} - #{msg_no_html}" }
      raise FlexibleIncludeError, "#{@page['path']} - #{msg_no_html}".red, [] if @die_on_path_denied

      "<p class='flexible_error'>#{msg}</p>"
    end

    def highlight(content, pattern)
      raise FlexibleIncludeError, "content is a #{content.class}, not a String" unless content.instance_of? String

      content.gsub(Regexp.new(pattern), "<span class='bg_yellow'>\\0</span>")
    end

    def maybe_raise_error(msg, throw_error: true)
      @logger.error { msg }
      return "<span class='flexible_error'>#{msg}</span>" unless throw_error

      raise FlexibleIncludeError, msg, []
    end

    def parse_args
      @copy_button = @helper.parameter_specified? 'copyButton'
      @dark = ' dark' if @helper.parameter_specified? 'dark'
      @do_not_escape = @helper.parameter_specified? 'do_not_escape'
      @download = @helper.parameter_specified? 'download'
      @from = @helper.parameter_specified? 'from'
      @highlight_pattern = @helper.parameter_specified? 'highlight'
      @label = @helper.parameter_specified? 'label'
      @label_specified = @label
      @number_lines = @helper.parameter_specified? 'number'
      @strip = @helper.parameter_specified? 'strip'
      @to = @helper.parameter_specified? 'to'
      @until = @helper.parameter_specified? 'until'

      # Download, dark, label or number implies pre
      @pre = @helper.parameter_specified?('pre') || @copy_button || @dark || @download || @label_specified || @number_lines

      @filename = @helper.parameter_specified? 'file'

      unless @filename # Do this after all other options have been checked for
        @filename = @helper.params.first.first
        @helper.delete_parameter @helper.params.first
      end
      raise StandardError, "@filename (#{@filename}) is not a string", [] unless @filename.instance_of? String

      @label ||= @filename

      @logger.debug("@filename=#{@filename}")
    end

    def remove_html_tags(string)
      string.gsub(/<[^>]*>/, '')
    end

    def render_completion
      unless @path.start_with?('!')
        unless File.exist?(@path) && Dir.exist?(File.dirname(@path))
          return maybe_raise_error(
            "#{@path} does not exist, referenced on line #{@line_number} (after front matter) of #{@page['path']}",
            throw_error: @die_on_file_error
          )
        end

        unless Pathname.new(@path).readable?
          return maybe_raise_error(
            "#{@path} is not readable, referenced on line #{@line_number} (after front matter) of #{@page['path']}",
            throw_error: @die_on_file_error
          )
        end

        @contents = File.read @path
        unless @contents.instance_of? String
          maybe_raise_error("contents has type #{@contents.class}, not a String",
                            throw_error: @die_on_file_error)
        end
      end

      @contents = FromToUntil.from(@contents, @from) if @from
      @contents = FromToUntil.to(@contents, @to) if @to
      @contents = FromToUntil.until(@contents, @until) if @until
      contents2 = @do_not_escape ? @contents : FlexibleClassMethods.escape_html(@contents)
      contents2.strip! if @strip
      maybe_raise_error("contents2 is a #{contents2.class}, not a String", throw_error: @die_on_file_error) unless contents2.instance_of? String

      contents2 = highlight(contents2, @highlight_pattern) if @highlight_pattern
      contents2 = FlexibleInclude.number_content(contents2) if @number_lines
      result = @pre ? wrap_in_pre(@path, contents2) : contents2
      <<~END_OUTPUT
        #{result}
        #{@helper.attribute if @helper.attribution}
      END_OUTPUT
    end

    def run(cmd)
      if cmd.empty?
        @do_not_escape = true
        return maybe_raise_error('FlexibleIncludeError: Empty command string', throw_error: @die_on_other_error)
      end

      @logger.debug { "Executing #{cmd}" }
      %x[#{cmd}].chomp
    rescue FlexibleIncludeError => e
      @logger.error { e.logger_message }
      exit! 1 if @die_on_any_flexible_include_error

      e.html_message
    rescue StandardError => e # Assumes the wasa the result of running a command; this might not be a valid assumption. Awaiting a bug report.
      @do_not_escape = true
      e = e.exception "'#{e.message}' while executing '#{cmd}'"
      maybe_reraise_error(e, throw_error: @die_on_run_error)
    end

    def setup
      @helper.gem_file __FILE__ # Enables attribution
      self.class.security_check

      config = @config[PLUGIN_NAME]
      if config
        @die_on_file_error  = config['die_on_file_error'] == true
        @die_on_other_error = config['die_on_other_error'] == true
        @die_on_path_denied = config['die_on_path_denied'] == true
        @die_on_run_error   = config['die_on_run_error'] == true
        @die_on_any_flexible_include_error = @die_on_file_error || @die_on_other_error || @die_on_path_denied || @die_on_run_error
      end

      parse_args
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
        <pre data-lt-active="false" class="pre_tag maxOneScreenHigh copyContainer#{@dark}" id="#{pre_id}">#{copy_button}#{content}</pre>
      END_PRE
    end
  end
end
