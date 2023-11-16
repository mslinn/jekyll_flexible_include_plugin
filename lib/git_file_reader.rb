require 'rugged'

# TODO: Not used yet. Either implement git-related functionality or delete this file and its tests
class GitFileReader
  def initialize(repo_dir = '.')
    @repo = Rugged::Repository.new repo_dir
  end

  def blob_at(ref, path)
    commit = @repo.rev_parse ref # Rugged::Commit
    @repo.blob_at(commit.oid, path) # Rugged::Blob
  end

  def commit_for_ref(ref)
    reference = @repo.ref ref # Rugged::Reference
    abort "Error: #{ref} is an invalid ref" if reference.nil?

    reference_direct = reference.type == :symbolic ? reference.target : reference
    @commit = reference_direct.target # Rugged::Commit
    self
  end

  # @return content of desired file
  def contents(filename)
    abort('Error: @commit is undefined; invoke commit_for_ref before invoking contents') if @commit.nil?

    tree = @commit.tree # Rugged::Tree
    entry = tree.get_entry filename # hash
    abort("Error: #{filename} is not present in commit #{commit.oid}") if entry.nil?

    sha = entry[:oid] # String
    object = @repo.read sha # Rugged::ObdObject; this is a blob
    object.data # String
  end
end
