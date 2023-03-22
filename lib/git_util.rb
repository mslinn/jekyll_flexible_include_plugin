require 'rugged'

class GitFileReader
  def initialize(repo_dir = '.')
    @repo = Rugged::Repository.new repo_dir
  end

  def commit_for_ref(ref)
    reference = @repo.ref ref # Rugged::Reference
    reference_direct = reference.type == :symbolic ? reference.target : reference
    @commit = reference_direct.target # Rugged::Commit
    self
  end

  # @return content of desired file
  def contents(filename)
    abort('@commit is undefined; invoke commit_for_ref before invoking contents') if @commit.nil?

    tree = @commit.tree # Rugged::Tree
    entry = tree.get_entry filename # hash
    abort("#{filename} is not present in commit #{commit.oid}") if entry.nil?

    sha = entry[:oid] # String
    object = @repo.read sha # Rugged::ObdObject
    object.data # String
  end
end

if $PROGRAM_NAME == __FILE__
  puts GitFileReader.new('.').commit_for_ref('HEAD').contents('README.md')
end
