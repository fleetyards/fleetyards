# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # The crafting questions that are about the export rather than the loader:
    # how much of the recipe catalogue arrives, and whether the source chain
    # still resolves across all of it. See
    # test/support/sc_data_contract_tree.rb.
    class BlueprintsContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        Blueprint.delete_all
      end

      # One full load, asserted from every angle. A load writes 1,607 records
      # with 15k recipe rows and 4k sources, so the assertions are gathered here
      # rather than each buying their own load.
      test "the export still carries the crafting catalogue" do
        real_tree_loader(::ScData::Loader::BlueprintsLoader).all

        assert_operator Blueprint.count, :>=, 1500

        refs = Blueprint.pluck(:sc_ref)
        assert_equal refs.uniq.size, refs.size

        slugs = Blueprint.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        assert_equal Blueprint.count, BlueprintBuild.current.count
        assert_empty Blueprint.where.missing(:build).pluck(:sc_key)

        assert_operator BlueprintCostSlot.count, :>=, 4000
        assert_operator BlueprintCostOption.count, :>=, 4000
        assert_operator BlueprintCostModifier.count, :>=, 6000

        assert_empty BlueprintCostOption.where(commodity_key: nil).pluck(:id)
        assert_empty BlueprintCostOption.where.not(cost_type: BlueprintCostOption::TYPES).pluck(:cost_type)
        assert_empty BlueprintCostModifier.where.not(ramp: BlueprintCostModifier::RAMPS).pluck(:ramp)

        assert_operator BlueprintSource.count, :>=, 3000
        assert_empty BlueprintSource.where.not(kind: BlueprintSource::KINDS).pluck(:kind)
        assert_operator BlueprintSource.where.not(org_name: nil).distinct.count(:org_name), :>=, 15

        # All three land: two off the export's `entityLawful` and one off the
        # curated list, which would otherwise be a value nothing ever writes.
        assert_equal BlueprintSource::ALIGNMENTS.sort,
          BlueprintSource.where.not(alignment: nil).distinct.pluck(:alignment).sort
        assert_empty BlueprintSource.where.not(alignment: BlueprintSource::ALIGNMENTS)
          .where.not(alignment: nil).pluck(:alignment)

        # The curated list wins over the flag rather than filling in for a
        # missing one: the export marks Wikelo lawful.
        assert_equal ["neutral"], BlueprintSource.where(org_name: "Wikelo Emporium").distinct.pluck(:alignment)

        # An unattributed source says nothing, the way it says no org. Every
        # attributed one answers, because all 38 reputation records state the
        # flag -- a null here would mean a faction arrived by a chain that never
        # reached its record.
        assert_empty BlueprintSource.where(org_name: nil).where.not(alignment: nil)
        assert_empty BlueprintSource.where.not(org_name: nil).where(alignment: nil)

        # 875 recipes appear in no pool and 26 more only in a pool nothing hands
        # out, so most of the catalogue has no stated source at all.
        assert_operator Blueprint.with_known_source.count, :>=, 600
        assert_operator Blueprint.with_known_source(false).count, :>=, 800
      end
    end
  end
end
