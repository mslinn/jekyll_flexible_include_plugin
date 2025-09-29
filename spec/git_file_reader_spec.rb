require 'jekyll_plugin_support'
require_relative '../lib/git_file_reader'

RSpec.describe(GitFileReader) do
  xit 'reads a file at a tag' do
    content = described_class.new('.').blob_at('v2.0.20', 'README.md').content
    expect(content).to include('Added `highlight` regex option')

    content = described_class.new('.').blob_at('v2.0.19', 'README.md').content
    expect(content).not_to include('Added `highlight` regex option')
  end

  it 'reads a file at HEAD^' do
    content = described_class.new('.').blob_at('HEAD^', 'README.md').content
    expect(content).to be_truthy
  end

  it 'reads a file at HEAD' do
    content = described_class.new('.').blob_at('HEAD', 'README.md').content
    expect(content).to be_truthy
  end

  it 'reads a file at refs/heads/master' do
    content = described_class.new('.').blob_at('refs/heads/master', 'README.md').content
    expect(content).to be_truthy
  end
end
