# frozen_string_literal: true

require "shellwords"
require 'key_value_parser'

class JekyllTagHelper
  attr_reader :argv, :liquid_context, :logger, :params, :tag_name

  def self.escape_html(string)
    string.gsub("&", "&amp;")
          .gsub("{", "&#123;")
          .gsub("}", "&#125;")
          .gsub("<", "&lt;")
  end

  # Expand a environment variable reference
  def self.expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) { ENV[Regexp.last_match(1)] }
  end

  # strip leading and trailing quotes if present
  def self.remove_quotes(string)
    string.strip.gsub(/\A'|\A"|'\Z|"\Z/, '').strip if string
  end

  def initialize(tag_name, markup, logger)
    @tag_name = tag_name
    @argv = Shellwords.split(markup)
    @keys_values = KeyValueParser.new.parse(@argv) # Hash[Symbol, String|Boolean]
    @logger = logger
    @logger.debug { "@keys_values='#{@keys_values}'" }
  end

  def delete_parameter(name)
    @params.delete(name)
    @argv.delete_if { |x| x.start_with? name }
    @keys_values.delete(name.to_sym)
  end

  # @return if parameter was specified, returns value and removes it from the available tokens
  def parameter_specified?(name)
    value = @keys_values[name.to_sym]
    delete_parameter(name)
    value
  end

  PREDEFINED_SCOPE_KEYS = [:include, :page].freeze

  # Finds variables defined in an invoking include, or maybe somewhere else
  # @return variable value or nil
  def dereference_include_variable(name)
    @liquid_context.scopes.each do |scope|
      next if PREDEFINED_SCOPE_KEYS.include? scope.keys.first

      value = scope[name]
      return value if value
    end
    nil
  end

  # @return value of variable, or the empty string
  def dereference_variable(name)
    value = @liquid_context[name] # Finds variables named like 'include.my_variable', found in @liquid_context.scopes.first
    value ||= @page[name] if @page # Finds variables named like 'page.my_variable'
    value ||= dereference_include_variable(name)
    value ||= ""
    value
  end

  # Sets @params by replacing any Liquid variable names with their values
  def liquid_context=(context)
    @liquid_context = context
    @params = @keys_values.map { |k, _v| lookup_variable(k) }
  end

  def lookup_variable(symbol)
    string = symbol.to_s
    return string unless string.start_with?("{{") && string.end_with?("}}")

    dereference_variable(string.delete_prefix("{{").delete_suffix("}}"))
  end

  def page
    @liquid_context.registers[:page]
  end
end
