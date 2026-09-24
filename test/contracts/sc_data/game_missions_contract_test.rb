# frozen_string_literal: true

require "test_helper"
require "support/sc_data_contract_tree"

module ScData
  module Contract
    # What the loader tests can no longer ask, because they read six curated
    # contracts rather than the export: whether the real tree still carries what
    # the catalogue is built on. See test/support/sc_data_contract_tree.rb for
    # why this cannot live beside them.
    class GameMissionsContractTest < ActiveSupport::TestCase
      include ScDataContractTree

      setup do
        require_real_tree

        GameMissionReward.delete_all
        GameMissionBuild.delete_all
        GameMission.delete_all
      end

      # One full load, asserted from every angle. A load writes 2,536 records
      # with about 3,400 rewards, so the assertions are gathered here rather than
      # each buying their own.
      test "the export still carries the contracts catalogue" do
        real_tree_loader(::ScData::Loader::GameMissionsLoader).all

        assert_operator GameMission.count, :>=, 2400

        # Across the whole export rather than six files: a generator that started
        # emitting a duplicate key is exactly what a curated fixture cannot see.
        refs = GameMission.pluck(:sc_ref)
        assert_equal refs.uniq.size, refs.size

        keys = GameMission.pluck(:sc_key)
        assert_equal keys.uniq.size, keys.size

        slugs = GameMission.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        assert_equal GameMission.count, GameMissionBuild.current.count

        # The flags that mean "in the files, in front of nobody". Both states
        # have to land: a load that wrote `true` everywhere would look exactly
        # like one that read the attribute correctly.
        assert_operator GameMission.where(released: false).count, :>=, 300
        assert_operator GameMission.where(released: true).count, :>=, 2000

        # Reputation is what a contract almost always pays, and so, it turns out,
        # is money: 2360 of the 2536 award currency.
        assert_operator GameMissionReward.of_kind("reputation").count, :>=, 2500
        assert_operator GameMissionReward.of_kind("currency").count, :>=, 2300

        # The split is the point. 8 contracts state a figure and the rest leave
        # it to the game -- and the exact 8 is asserted because it is why the
        # catalogue shows no aUEC payout: if it grows, the export has started
        # stating payouts and the catalogue can start showing them.
        assert_equal 8, GameMissionReward.of_kind("currency").where.not(amount: nil).count
        assert_operator GameMissionReward.of_kind("currency").where(amount: nil).count, :>=, 2300

        # A reputation loss is a reward too, and the parser has to keep the sign:
        # 16 of the 58 amounts the export declares are negative.
        assert_operator GameMissionReward.of_kind("reputation").where(amount: ...0).count, :>=, 1

        # Every item award names something rather than a GUID: the two commonest
        # are physical currency, which is the closest the export comes to stating
        # a payout per contract.
        assert_operator GameMissionReward.of_kind("item").where.not(entity_name: nil).count, :>=, 390
        assert_includes GameMissionReward.of_kind("item").distinct.pluck(:entity_name), "MG Scrip"

        # The link to the crafting catalogue, which is the reverse of what a
        # blueprint's sources already answer.
        assert_operator GameMission.where.not(blueprint_pool_refs: []).count, :>=, 700

        # Read off the difficulty the contract declares under its results, not
        # off the contract itself -- digging at the contract found none of them.
        assert_operator GameMission.where.not(difficulty_profile: nil).count, :>=, 2000
        assert_empty GameMission.where.not(difficulty_mechanical_skill: [nil, *1..7]).pluck(:sc_key)
      end
    end
  end
end
