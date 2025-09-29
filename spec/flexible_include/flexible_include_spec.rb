require 'jekyll_plugin_support'
require_relative '../../lib/flexible_include'

RSpec.describe(FlexibleInclude::FlexibleInclude) do
  it 'controls access to files' do
    ENV['FLEXIBLE_INCLUDE_PATHS'] = '~/.*:spec/.*'

    described_class.send(:new, 'my_tag', '', Liquid::ParseContext.new)
    described_class.security_check
    expect(described_class.access_allowed(__FILE__)).to be_truthy

    expect(described_class.access_allowed('~/.mem_settings.yaml')).to be_truthy

    expect(described_class.access_allowed('/asdf')).to be_falsey
  end

  it 'controls access to git content' do
    home_file = JekyllSupport::JekyllPluginHelper.expand_env '$HOME/.mem_settings.yaml'
    expect(described_class.access_allowed(home_file)).to be_truthy
  end
end
