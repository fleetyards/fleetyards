# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # The reason `ScData::ParsedCheck` exists, asked of the tree that is actually
    # loaded: a build that arrives half-uploaded, a category the export renamed, a
    # parse that stopped between catalogues. None of those raise anywhere -- they
    # produce a tree that loads and quietly retires whatever it no longer carries.
    #
    # `bin/scdata check` already asks this before a push. This asks it again of
    # what the bucket is serving, which is what a pull actually got.
    class ParsedCheckContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree
      end

      test "#call passes the parsed tree the configured build points at" do
        result = ::ScData::ParsedCheck.new.call

        assert_predicate result, :ok?, result.problems.first(20).join("\n")
      end
    end
  end
end
