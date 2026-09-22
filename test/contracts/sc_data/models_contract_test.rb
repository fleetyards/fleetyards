# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # A ship's hardpoints come out of the real tree, and how many the export
    # still carries for one is a question no curated fixture can answer. See
    # test/support/sc_data_contract_tree.rb.
    class ModelsContractTest < ActiveSupport::TestCase
      include HangarImportFixtures
      include ScDataContractTree

      setup do
        require_real_tree

        clean_loader_tables
      end

      test "#one loads data from game files" do
        loader = real_tree_loader(::ScData::Loader::ModelsLoader)
        manufacturer = create(:manufacturer, name: "Roberts Space Industries", slug: "rsi", code: "RSI")
        model = create(:model, :in_game, name: "Constellation Andromeda", manufacturer: manufacturer)

        assert_difference -> { Hardpoint.where(parent: model).count }, 95 do
          loader.one(model)
        end
      end
    end
  end
end
