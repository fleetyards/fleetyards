# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class GameMissionsLoaderTest < ActiveSupport::TestCase
      setup do
        GameMission.delete_all
        @loader = ::ScData::Loader::GameMissionsLoader.new
      end

      # One full load, asserted from every angle. A load writes 2,536 records
      # with about 3,400 rewards, and the suite pays for it twice over -- once
      # to write it and again to roll it back -- so the assertions are gathered
      # here rather than each buying their own load.
      test "#all loads the catalogue, its builds and its rewards" do
        @loader.all

        assert_operator GameMission.count, :>=, 2400

        refs = GameMission.pluck(:sc_ref)
        assert_equal refs.uniq.size, refs.size

        keys = GameMission.pluck(:sc_key)
        assert_equal keys.uniq.size, keys.size

        slugs = GameMission.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        assert_equal GameMission.count, GameMissionBuild.current.count
        assert_empty GameMission.where.missing(:build).pluck(:sc_key)

        # The flags that mean "in the files, in front of nobody". Both states
        # have to land: a load that wrote `true` everywhere would look exactly
        # like one that read the attribute correctly.
        assert_operator GameMission.where(released: false).count, :>=, 300
        assert_operator GameMission.where(released: true).count, :>=, 2000

        assert_empty GameMissionReward.where.not(kind: GameMissionReward::KINDS).pluck(:kind)

        # Reputation is what a contract almost always pays, and currency is what
        # eight of them pay. The exact figure is asserted because it is the
        # whole of D3: if this number grows, the export has started stating
        # payouts and the catalogue can start showing them.
        assert_operator GameMissionReward.of_kind("reputation").count, :>=, 2500
        assert_equal 8, GameMissionReward.of_kind("currency").count

        # A reputation loss is a reward too, and the parser has to keep the
        # sign: 16 of the 58 amounts the export declares are negative.
        assert_operator GameMissionReward.of_kind("reputation").where(amount: ...0).count, :>=, 1

        # The denormalised list and the rows it is drawn from cannot disagree:
        # the list is what a filter reads and the rows are what a page renders.
        # "blueprint" is the one entry with no row behind it -- a recipe comes
        # from a reward pool rather than from a contract result -- so it is
        # asserted against the pools instead.
        mismatched = GameMissionBuild.current.includes(:rewards).reject do |build|
          stated = build.rewards.map(&:kind).uniq
          stated << GameMissionBuild::BLUEPRINT_REWARD_KIND if build.blueprint_pool_refs.any?

          build.reward_kinds.sort == stated.uniq.sort
        end
        assert_empty mismatched.map(&:name)

        assert_empty GameMissionBuild.current.where.not(reward_kinds: []).where("NOT (reward_kinds <@ ARRAY[?]::text[])", GameMissionBuild::REWARD_KINDS).pluck(:name)

        # Every item award names something rather than a GUID: the two commonest
        # are physical currency, which is the closest the export comes to
        # stating a payout per contract.
        assert_operator GameMissionReward.of_kind("item").where.not(entity_name: nil).count, :>=, 390
        assert_includes GameMissionReward.of_kind("item").distinct.pluck(:entity_name), "MG Scrip"

        # An unattributed mission says nothing about alignment, the way it says
        # no org. Every attributed one answers, because all 38 reputation
        # records state the flag -- a null here would mean a faction arrived by
        # a chain that never reached its record.
        assert_empty GameMission.where(org_name: nil).where.not(alignment: nil).pluck(:sc_key)
        assert_empty GameMission.where.not(org_name: nil).where(alignment: nil).pluck(:sc_key)

        # The curated list wins over the export's flag rather than filling in
        # for a missing one, exactly as it does for a blueprint source.
        assert_empty GameMission.where.not(alignment: [nil, *BlueprintSource::ALIGNMENTS]).pluck(:alignment)

        # The link to the crafting catalogue, which is the reverse of what a
        # blueprint's sources already answer -- and which a reader can filter
        # for, because it is carried as a reward kind.
        assert_operator GameMission.where.not(blueprint_pool_refs: []).count, :>=, 700
        assert_equal GameMission.where.not(blueprint_pool_refs: []).count,
          GameMission.rewarding(GameMissionBuild::BLUEPRINT_REWARD_KIND).count

        # Read off the difficulty the contract declares under its results, not
        # off the contract itself -- digging at the contract found none of them.
        assert_operator GameMission.where.not(difficulty_profile: nil).count, :>=, 2000
        assert_empty GameMission.where.not(difficulty_mechanical_skill: [nil, *1..7]).pluck(:sc_key)
      end

      # A second run of the same build rewrites the build in place rather than
      # colliding on the unique index, and the rewards go with it rather than
      # doubling.
      test "#all is idempotent for a build that is already loaded" do
        @loader.all

        missions = GameMission.count
        rewards = GameMissionReward.count

        ::ScData::Loader::GameMissionsLoader.new.all

        assert_equal missions, GameMission.count
        assert_equal rewards, GameMissionReward.count
        assert_equal missions, GameMissionBuild.current.count
      end

      # A contract the export drops keeps its row -- a link to it still has to
      # resolve -- and loses the build, which is what takes it out of the
      # catalogue.
      test "#all retires a mission the build no longer carries" do
        dropped = create(:game_mission, sc_ref: "gone", sc_key: "generator_gone")

        @loader.all

        dropped.reload

        assert_nil dropped.version
        assert_empty dropped.builds.current
        assert dropped.retired?
      end
    end
  end
end
