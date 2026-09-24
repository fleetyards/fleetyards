# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # An export whose shape moved -- a renamed field, a category that stopped
    # being written -- shows up as a load that stops producing components, and no
    # curated fixture can tell you that. A load of the real tree walks ~7,800
    # files and writes ~7,300 components per call, which is why it happens here
    # rather than beside the loader tests. See
    # test/support/sc_data_contract_tree.rb.
    class ItemsContractTest < ActiveSupport::TestCase
      include HangarImportFixtures
      include ScDataContractTree

      setup do
        require_real_tree

        clean_loader_tables
      end

      test "the export still carries the items catalogue" do
        initial = Component.where.not(version: nil).count

        real_tree_loader(::ScData::Loader::ItemsLoader).all

        assert_operator Component.where.not(version: nil).count - initial, :>=, 5000
      end

      # Specifically about the tree rather than the loader: the parser used to
      # write the whole JSON array as a single string inside the array
      # (`["[\"flightReady\"]"]`), and a tree parsed before that was fixed still
      # carries those values however current the parser is. `tags` is published
      # now, so a stale tree has to fail here rather than on the page.
      test "the tree carries one entry per tag, not the array's own inspect output" do
        real_tree_loader(::ScData::Loader::ItemsLoader).all

        tagged = Component.where(version: ::ScData::Source.version)
          .where.not(tags: [nil, "[]"])

        assert_operator tagged.count, :>=, 1000,
          "the tree carries tags for thousands of items; none arrived"

        # Every row rather than a sample, and in SQL rather than by deserialising
        # 3,400 of them: a tag starting with `[` is stored as the two characters
        # `"[`, so the whole column can be asked at once.
        mangled = tagged.where("tags LIKE ?", '%"[%').pluck(:sc_key)

        assert_empty mangled,
          "these carry a re-encoded array rather than tags -- the tree predates the parser fix that stopped re-encoding tag arrays"
      end
    end
  end
end
