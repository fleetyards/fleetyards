# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # An export that stopped parsing -- a renamed field, a tree that failed to
    # sync -- reads as a load that stops producing records, which no curated
    # fixture can tell you. See test/support/sc_data_contract_tree.rb.
    class EquipmentContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        Equipment.delete_all
      end

      test "the export still carries the equipment catalogue" do
        real_tree_loader(::ScData::Loader::EquipmentLoader).all

        assert_operator Equipment.count, :>=, 4_000

        sc_keys = Equipment.pluck(:sc_key)
        assert_equal sc_keys.uniq.size, sc_keys.size
      end
    end
  end
end
