# frozen_string_literal: true

# The other half of test/fixtures/sc_data: the tests that have to read the real
# parsed tree, because what they ask about is the export's shape rather than the
# loader's behaviour.
#
# A curated fixture cannot answer those. A renamed field, a category that stopped
# being written, a payout the export started stating -- each of them looks
# exactly like a fixture nobody refreshed, so the question has to be put to the
# tree itself.
#
# What it must not be put to is a pull request. A fork or Dependabot branch reads
# no object-storage credentials, so the pull falls through to whatever tree the
# cache happened to keep -- and these assertions then describe a build nobody
# chose. That is not a flake to be re-run: the numbers are real, they just belong
# to an export from months ago.
#
# So they skip unless the tree is on disk, and the sc-data-contract workflow,
# which pulls it, is what runs them. `SC_DATA_CONTRACT` is that workflow's
# signal: it turns a missing tree from a skip into a failure, so a pull that
# quietly fetched nothing cannot pass as a green contract run.
module ScDataContractTree
  def self.tree_root
    ::ScData::Loader::BaseLoader::DEFAULT_BASE_FOLDER
      .join("parsed", ::ScData::Source.environment.to_s)
  end

  def self.tree?
    tree_root.directory? && tree_root.children.any?
  end

  # A loader pointed at the real tree, for the handful of tests that need one.
  # The counterpart of `fixture_loader`, and named to say which it is at the
  # call site.
  def real_tree_loader(loader_class)
    require_real_tree

    loader_class.new
  end

  def require_real_tree
    return if ScDataContractTree.tree?

    if ENV["SC_DATA_CONTRACT"].present?
      flunk <<~MESSAGE.squish
        SC_DATA_CONTRACT is set, so this is a contract run, but there is no
        parsed tree at #{ScDataContractTree.tree_root} -- the pull fetched
        nothing and a skip here would have read as a pass.
      MESSAGE
    end

    skip "no parsed sc_data tree on disk; the sc-data-contract workflow pulls it"
  end
end
