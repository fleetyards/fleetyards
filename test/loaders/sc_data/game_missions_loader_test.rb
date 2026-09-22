# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class GameMissionsLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      setup do
        GameMissionReward.delete_all
        GameMissionBuild.delete_all
        GameMission.delete_all
      end

      def loader
        fixture_loader(::ScData::Loader::GameMissionsLoader)
      end

      # Six contracts, each present for a branch of the loader. See the fixture
      # README for which is which; a load of the real tree writes 2,536 of them
      # with about 3,400 rewards, and this file used to buy that three times.
      test "#all loads the catalogue and a current build per contract" do
        loader.all

        assert_equal 6, GameMission.count

        refs = GameMission.pluck(:sc_ref)
        assert_equal refs.uniq.size, refs.size

        keys = GameMission.pluck(:sc_key)
        assert_equal keys.uniq.size, keys.size

        slugs = GameMission.pluck(:slug)
        assert_equal slugs.uniq.size, slugs.size

        # Against `fixture_source` rather than the configured one: these records
        # came from the fixture tree, so the build they carry names the fixture
        # environment. Asked about `live`, every one of them would read as a
        # mission with no build at all.
        assert_equal GameMission.count, GameMissionBuild.current(fixture_source).count
        assert_equal GameMission.count,
          GameMissionBuild.current(fixture_source).distinct.count(:game_mission_id)
      end

      # Both states have to land: a load that wrote `true` everywhere would look
      # exactly like one that read the attribute correctly.
      test "#all keeps the released flag in both states" do
        loader.all

        assert_equal 1, GameMission.where(released: false).count
        assert_equal 5, GameMission.where(released: true).count
      end

      test "#all writes only reward kinds the model declares" do
        loader.all

        assert_empty GameMissionReward.where.not(kind: GameMissionReward::KINDS).pluck(:kind)
      end

      # The split is the point: one fixture states a figure and the rest leave it
      # to the game. How many do so across the whole export is a question for the
      # contract test -- that it is read at all is this one.
      test "#all keeps a stated payout and leaves the rest open" do
        loader.all

        stated = GameMissionReward.of_kind("currency").where.not(amount: nil)

        assert_equal 1, stated.count
        assert_equal 3000, stated.first.amount
        assert_equal 5, GameMissionReward.of_kind("currency").where(amount: nil).count
      end

      # Said once per mission however often the contract repeats it across
      # outcomes -- a duplicate would render as a payout stated twice.
      test "#all writes a contract's currency reward once" do
        loader.all

        assert_empty GameMissionBuild.current(fixture_source)
          .joins(:rewards).where(game_mission_rewards: {kind: "currency"})
          .group("game_mission_builds.id").having("COUNT(*) > 1").pluck(:name)
      end

      # A reputation loss is a reward too, and the parser has to keep the sign.
      test "#all keeps the sign on a reputation loss" do
        loader.all

        assert_equal 2, GameMissionReward.of_kind("reputation").where(amount: ...0).count
      end

      # The denormalised list and the rows it is drawn from cannot disagree: the
      # list is what a filter reads and the rows are what a page renders.
      # "blueprint" is the one entry with no row behind it -- a recipe comes from
      # a reward pool rather than from a contract result -- so it is asserted
      # against the pools instead.
      test "#all keeps reward_kinds in step with the rewards and the pools" do
        loader.all

        mismatched = GameMissionBuild.current(fixture_source).includes(:rewards).reject do |build|
          stated = build.rewards.map(&:kind).uniq
          stated << GameMissionBuild::BLUEPRINT_REWARD_KIND if build.blueprint_pool_refs.any?

          build.reward_kinds.sort == stated.uniq.sort
        end

        assert_empty mismatched.map(&:name)

        assert_empty GameMissionBuild.current(fixture_source).where.not(reward_kinds: [])
          .where("NOT (reward_kinds <@ ARRAY[?]::text[])", GameMissionBuild::REWARD_KINDS)
          .pluck(:name)
      end

      # An unattributed mission says nothing about alignment, the way it says no
      # org. Every attributed one answers, because the record states the flag --
      # a null here would mean a faction arrived by a chain that never reached
      # its record.
      test "#all answers alignment exactly when the contract names an org" do
        loader.all

        assert_empty GameMission.where(org_name: nil).where.not(alignment: nil).pluck(:sc_key)
        assert_empty GameMission.where.not(org_name: nil).where(alignment: nil).pluck(:sc_key)

        assert_equal 1, GameMission.where(org_name: nil).count
      end

      # The curated list wins over the export's flag rather than filling in for a
      # missing one, exactly as it does for a blueprint source.
      test "#all takes alignment from the curated list" do
        loader.all

        assert_empty GameMission.where.not(alignment: [nil, *BlueprintSource::ALIGNMENTS]).pluck(:alignment)

        lawful = GameMission.find_by(sc_key: "2025content_firesale_cfp")
        unlawful = GameMission.find_by(sc_key: "2025content_firesale_hh")

        refute_equal lawful.alignment, unlawful.alignment
      end

      # The link to the crafting catalogue, which is the reverse of what a
      # blueprint's sources already answer -- and which a reader can filter for,
      # because it is carried as a reward kind.
      test "#all carries the blueprint pools a contract rewards" do
        loader.all

        assert_equal 2, GameMission.where.not(blueprint_pool_refs: []).count
        assert_equal GameMission.where.not(blueprint_pool_refs: []).count,
          GameMission.rewarding(GameMissionBuild::BLUEPRINT_REWARD_KIND, fixture_source).count
      end

      # Read off the difficulty the contract declares under its results, not off
      # the contract itself -- digging at the contract found none of them.
      test "#all reads the difficulty off the contract's results" do
        loader.all

        assert_equal 6, GameMission.where.not(difficulty_profile: nil).count
        assert_empty GameMission.where.not(difficulty_mechanical_skill: [nil, *1..7]).pluck(:sc_key)
      end

      test "#all names the entity an item reward hands over" do
        loader.all

        assert_equal ["MG Scrip"], GameMissionReward.of_kind("item").distinct.pluck(:entity_name)
      end

      # A second run of the same build rewrites the build in place rather than
      # colliding on the unique index, and the rewards go with it rather than
      # doubling.
      test "#all is idempotent for a build that is already loaded" do
        loader.all

        missions = GameMission.count
        rewards = GameMissionReward.count

        loader.all

        assert_equal missions, GameMission.count
        assert_equal rewards, GameMissionReward.count
        assert_equal missions, GameMissionBuild.current(fixture_source).count
      end

      # A contract the export drops keeps its row -- a link to it still has to
      # resolve -- and loses the build, which is what takes it out of the
      # catalogue.
      test "#all retires a mission the build no longer carries" do
        # The factory builds against the configured environment, which a fixture
        # load never touches -- so the build has to be written into the fixture
        # source by hand for there to be anything here to retire.
        dropped = create(:game_mission, :without_build, sc_ref: "gone", sc_key: "generator_gone")
        dropped.builds.create!(
          environment: fixture_source.environment,
          version: fixture_source.version,
          **dropped.attributes.symbolize_keys.slice(*GameMissionBuild::FACTS)
        )

        loader.all

        dropped.reload

        assert_nil dropped.version
        assert_empty dropped.builds.current(fixture_source)
      end

      # What a build whose files failed to sync looks like from the loader's
      # side: nothing to load, and so nothing claiming to be the current build.
      test "#all writes nothing for a tree that carries no contracts" do
        empty_tree_loader(::ScData::Loader::GameMissionsLoader).all

        assert_equal 0, GameMission.count
      end
    end
  end
end
