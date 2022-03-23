# frozen_string_literal: true

require "jekyll"
require "jekyll_plugin_logger"
require "liquid"
require_relative "flexible_include/version"

module JekyllFlexibleIncludeName
  PLUGIN_NAME = "flexible_include"
end

module Jekyll
  module Tags
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

      def initialize(tag_name, markup, tokens)
        super
        @logger = PluginLogger.new
        matched = markup.strip.match(VARIABLE_SYNTAX)
        if matched
          @file = matched["variable"].strip
          @params = matched["params"].strip
        else
          @file, @params = markup.strip.split(%r!\s+!, 2)
        end
        @tag_name = tag_name
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

      def expand_env(str)
        str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV[$1] }
      end

      # Grab file read opts in the context
      def file_read_opts(context)
        context.registers[:site].file_read_opts
      end

      # Render the variable if required
      def render_variable(context)
        if @file.match VARIABLE_SYNTAX
          partial = context.registers[:site]
            .liquid_renderer
            .file("(variable)")
            .parse(@file)
          partial.render!(context)
        end
      end

      def render(context) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        file = render_variable(context) || @file
        puts { "flexible_include #{file}" }
        file = file.gsub!(/\A'|'\Z/, '') || file # strip leading and trailing quotes if present
        file = expand_env(file)
        path = file
        if /^\//.match(file)  # Is the file absolute?
          @logger.debug { "render path=#{path}, file=#{file}" }
        elsif /~/.match(file)  # Is the file relative to user's home directory?
          @logger.debug { "render original file=#{file}, path=#{path}" }
          file.slice! "~/"
          path = File.join(ENV['HOME'], file)
          @logger.debug { "render path=#{path}, file=#{file}" }
        elsif /\!/.match(file)  # execute command and return response
          file.slice! "!"
          @logger.debug { "render command=#{file}" }
          contents = run(file)
          escaped_contents = escape_html?(context) ? escape_html(contents) : contents
          return escaped_contents
        else  # The file is relative
          site = context.registers[:site]
          source = File.expand_path(site.config['source']) # website root directory
          path = File.join(source, file)  # Fully qualified path of include file
          @logger.debug { "render file=#{file}, path=#{path}, source=#{source}" }
        end
        return unless path

        begin
          escaped_contents = escape_html(read_file(path, context))
          @logger.debug { escaped_contents }
          partial = Liquid::Template.parse(escaped_contents)
        rescue StandardError => e
          abort "flexible_include.rb: #{e.message}"
        end

        context.stack do
          begin
            contents = read_file(path, context)
            escaped_contents = escape_html?(context) ? escape_html(contents) : contents
            partial = Liquid::Template.parse(escaped_contents)
          rescue StandardError => e
            abort "flexible_include.rb: #{e.message}"
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

      def run(cmd)
        %x[ #{cmd} ].chomp
      end

      def valid_include_file?(path, dir, safe)
        !outside_site_source?(path, dir, safe) && File.file?(path)
      end

      def outside_site_source?(path, dir, safe)
        safe && !realpath_prefixed_with?(path, dir)
      end

      def realpath_prefixed_with?(path, dir)
        File.exist?(path) && File.realpath(path).start_with?(dir)
      rescue StandardError
        false
      end

      # This method allows to modify the file content by inheriting from the class.
      def read_file(file, context)
        File.read(file, **file_read_opts(context))
      end

      private

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
  end
end

PluginMetaLogger.instance.info { "Loaded #{JekyllFlexibleIncludeName::PLUGIN_NAME} v#{JekyllFlexibleIncludePlugin::VERSION} plugin." }
Liquid::Template.register_tag('flexible_include', Jekyll::Tags::FlexibleInclude)
