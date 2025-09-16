require 'benchmark'
require 'jekyll_plugin_support'
require 'securerandom'
require_relative 'flexible_include/version'
require_relative 'flexible_include_class'
require_relative 'flexible_include_private_methods'

class String
  def squish
    strip.gsub(/\s+/, ' ')
  end
end

module FlexibleInclude
  include FlexiblePrivateMethods

  FlexibleIncludeError = JekyllSupport.define_error

  PLUGIN_NAME = 'flexible_include'.freeze

  class FlexibleInclude < JekyllSupport::JekyllTag
    include JekyllFlexibleIncludePluginVersion

    class << self
      include FlexibleClassMethods
    end

    def html_message(error)
      <<~END_MSG
        <div class='#{error.class.name.snakecase}'>
          #{self.class} raised in #{calling_file} while processing line #{line_number} (after front matter) of #{path}
          #{message}
        </div>
      END_MSG
    end

    # Look for *nix version of @path if Windows expansion did not yield a file that exists
    def render_impl
      setup
      @path = ::JekyllSupport::JekyllPluginHelper.expand_env @filename, @logger
      linux_path = `wslpath '#{@path}' 2>/dev/null`.chomp
      @path = linux_path if !File.exist?(@path) && File.exist?(linux_path)
      handle_path_types
      render_completion
    rescue Errno::EACCES => e
      e.shorten_backtrace
      @logger.error { "#{e.class.name}: #{e.message}" }
      exit! 1 if @die_on_file_error

      html_message
    rescue Errno::ENOENT => e
      e.shorten_backtrace
      @logger.error { "#{e.class.name}: #{e.message}" }
      exit! 1 if @die_on_path_denied

      html_message
    rescue FlexibleIncludeError => e
      @logger.error { e.logger_message }
      exit! if @die_on_other_error

      html_message
      # rescue StandardError => e
      #   @logger.error { e.full_message }
      #   exit! 4

      #   html_message
    end

    private

    include FlexiblePrivateMethods

    # @return content if @path does not reference a file
    def handle_path_types
      case @path
      when /\A\// # Absolute path
        unless self.class.access_allowed(@path)
          return denied("Access to <code>#{@path}</code> from line #{@line_number} (after front matter) " \
                        "of #{@page['name']} denied by <code>FLEXIBLE_INCLUDE_PATHS</code> value.")
        end

        @logger.debug { "Absolute @path=#{@path}, @filename=#{@filename}" }
      when /\A~/ # Relative path to user's home directory
        unless self.class.access_allowed(@path)
          return denied("Access to <code>#{@path}</code> from line #{@line_number} (after front matter) " \
                        "of #{@page['name']} denied by <code>FLEXIBLE_INCLUDE_PATHS</code> value.")
        end

        @logger.debug { "User home start @filename=#{@filename}, @path=#{@path}" }
        @filename = @filename.delete_prefix '~/'
        @filename = File.join(Dir.home, @filename)
        @path = @filename
        @logger.debug { "User home end @filename=#{@filename}, @path=#{@path}" }
      when /\A!/ # Run command and return response
        if @execution_denied
          return denied("Arbitrary command execution from line #{@line_number} (after front matter) " \
                        "of #{@page['name']} denied by DISABLE_FLEXIBLE_INCLUDE value.")
        end

        @filename = ::JekyllSupport::JekyllPluginHelper.remove_quotes(@helper.argv.first) if @helper.argv.first
        @filename = @filename.delete_prefix '!'
        @contents = run(@filename)
      else # Relative path
        @path = @filename
        @relative = true
        @logger.debug { "Relative end @filename=#{@filename}, @path=#{@path}" }
      end
    end

    ::JekyllSupport::JekyllPluginHelper.register(self, 'flexible_include')
  end
end
