module FlexibleInclude
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
      ::JekyllSupport::JekyllPluginHelper.expand_env(path, die_if_undefined: true)
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
end
