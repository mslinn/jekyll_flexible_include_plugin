# frozen_string_literal: true

require_relative "../lib/flexible_include"

RSpec.describe(FlexibleInclude) do
  it "controls access to files" do
    ENV['FLEXIBLE_INCLUDE_PATHS'] = '~/.*:spec/.*'

    FlexibleInclude.send(:new, 'my_tag', "", Liquid::ParseContext.new)
    FlexibleInclude.security_check
    expect(FlexibleInclude.access_allowed(__FILE__)).to be_truthy

    expect(FlexibleInclude.access_allowed("~/.mem_settings.yaml")).to be_truthy

    home_file = JekyllTagHelper.expand_env("$HOME/.mem_settings.yaml")
    expect(FlexibleInclude.access_allowed(home_file)).to be_truthy

    expect(FlexibleInclude.access_allowed('/asdf')).to be_falsey
  end
end
