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

FlexibleIncludeError = Class.new(Liquid::Error)

module FlexibleInclude
  PLUGIN_NAME = 'flexible_include'.freeze

  class FlexibleInclude < JekyllSupport::JekyllTag
    include JekyllFlexibleIncludePluginVersion

    class << self
      include FlexibleClassMethods
    end

    def render_impl
      setup
      path = JekyllPluginHelper.expand_env @filename
      contents = handle_path_types path
      raise FlexibleIncludeError, "C: contents of '#{path}' is a #{contents.class}, not a String" unless contents.instance_of? String

      render_completion(path, contents)
    rescue Errno::EACCES => e
      msg = format_error_message e.message
      e.message = msg
      e.set_backtrace e.backtrace[0..9]
      @logger.error msg
      raise e if @die_on_file_error

      "<span class='flexible_error'>StandardError: #{msg}</span>"
    rescue Errno::ENOENT => e
      msg = format_error_message e.message
      e.message = msg
      e.set_backtrace e.backtrace[0..9]
      @logger.error msg
      raise e if @die_on_path_denied

      "<span class='flexible_error'>StandardError: #{msg}</span>"
    rescue FlexibleIncludeError => e
      @logger.error e.message
      e.set_backtrace e.backtrace[0..9]
      raise e
    rescue StandardError => e
      msg = format_error_message e.message
      @logger.error msg
      e.set_backtrace e.backtrace[0..9]
      raise e if @die_on_other_error

      "<span class='flexible_error'>StandardError: #{msg}</span>"
    end

    private

    include FlexiblePrivateMethods

    # @return content if path does not reference a file
    def handle_path_types(path)
      case path
      when /\A\// # Absolute path
        return denied("Access to <code>#{path}</code> denied by <code>FLEXIBLE_INCLUDE_PATHS</code> value.") unless self.class.access_allowed(path)

        @logger.debug { "Absolute path=#{path}, @filename=#{@filename}" }
        ''
      when /\A~/ # Relative path to user's home directory
        return denied("Access to <code>#{path}</code> denied by <code>FLEXIBLE_INCLUDE_PATHS</code> value.") unless self.class.access_allowed(path)

        @logger.debug { "User home start @filename=#{@filename}, path=#{path}" }
        @filename = @filename.delete_prefix '~/'
        path = File.join(Dir.home, @filename)
        @logger.debug { "User home end @filename=#{@filename}, path=#{path}" }
        ''
      when /\A!/ # Run command and return response
        return denied('Arbitrary command execution denied by DISABLE_FLEXIBLE_INCLUDE value.') if @execution_denied

        @filename = JekyllPluginHelper.remove_quotes(@helper.argv.first) if @helper.argv.first
        @filename = @filename.delete_prefix '!'
        run(@filename)
      else # Relative path
        source = File.expand_path(@site.config['source']) # website root directory
        path = File.join(source, @filename) # Fully qualified path of include file from relative path
        @relative = true
        @logger.debug { "Relative end @filename=#{@filename}, path=#{path}" }
        ''
      end
    end

    JekyllPluginHelper.register(self, 'flexible_include')
  end
end
