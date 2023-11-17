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
  FlexibleIncludeError = JekyllSupport.define_error

  PLUGIN_NAME = 'flexible_include'.freeze

  class FlexibleInclude < JekyllSupport::JekyllTag
    include JekyllFlexibleIncludePluginVersion

    class << self
      include FlexibleClassMethods
    end

    def render_impl
      puts ">>> #{@tag_name} #{@argument_string}".yellow
      setup
      @path = JekyllPluginHelper.expand_env @filename
      handle_path_types
      render_completion
    rescue Errno::EACCES => e
      e.backtrace = e.backtrace[0..3].map { |x| x.gsub(Dir.pwd + '/', './') }
      msg = format_error_message e.message
      e.message = msg
      @logger.error msg
      raise e if @die_on_file_error

      "<span class='standard_error'>StandardError: #{msg}</span>"
    rescue Errno::ENOENT => e
      e.backtrace = e.backtrace[0..3].map { |x| x.gsub(Dir.pwd + '/', './') }
      msg = format_error_message e.message
      e.message = msg
      @logger.error msg
      raise e if @die_on_path_denied

      "<span class='standard_error'>StandardError: #{msg}</span>"
    rescue FlexibleIncludeError => e
      e.backtrace = e.backtrace[0..3].map { |x| x.gsub(Dir.pwd + '/', './') }
      @logger.error e.message
      raise e
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

        @filename = JekyllPluginHelper.remove_quotes(@helper.argv.first) if @helper.argv.first
        @filename = @filename.delete_prefix '!'
        @contents = run(@filename)
      else # Relative path
        @path = @filename
        @relative = true
        @logger.debug { "Relative end @filename=#{@filename}, @path=#{@path}" }
      end
    end

    JekyllPluginHelper.register(self, 'flexible_include')
  end
end
