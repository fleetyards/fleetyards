# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class FactionsLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      setup do
        FactionLadder.delete_all
        FactionBuild.delete_all
        Faction.delete_all
      end

      def loader
        fixture_loader(::ScData::Loader::FactionsLoader)
      end

      test "#all loads a faction, its build and its ladders" do
        loader.all

        faction = Faction.find_by!(slug: "foxwellenforcement")
        build = faction.builds.sole

        assert_equal "factionreputation_lawful_foxwellenforcement", faction.sc_key
        assert_equal "Foxwell Enforcement", build.name
        assert_equal FIXTURE_ENVIRONMENT, build.environment
        assert build.lawful
        assert_equal "lawful", build.alignment
        assert_equal "Standing", build.ladders.first.name
        assert_equal "Affinity", build.ladders.last.name
        assert_equal({"name" => "Neutral", "min_reputation" => 0}, build.ladders.first.ranks.first)
      end

      test "#all takes a curated alignment off the record's key" do
        loader.all

        assert_equal "neutral", Faction.find_by!(slug: "wikelo").builds.sole.alignment
      end

      test "#all reloading a build replaces its ladders" do
        loader.all

        build = Faction.find_by!(slug: "foxwellenforcement").builds.sole
        count = build.ladders.count
        build.ladders.first.update!(name: "Stale")

        fixture_loader(::ScData::Loader::FactionsLoader).all

        assert_equal count, build.reload.ladders.count
        assert_not_includes build.ladders.pluck(:name), "Stale"
      end

      test "#all retires a faction the export dropped" do
        gone = create(:faction, sc_key: "factionreputation_gone", version: ::ScData::Source.version, with_build: false)
        gone.builds.create!(environment: FIXTURE_ENVIRONMENT, version: ::ScData::Source.version, name: "Gone")

        loader.all

        assert_nil gone.reload.version
        assert_empty gone.builds
      end

      test "#one attaches the logo only when loading the default environment" do
        data = JSON.parse(File.read(FIXTURE_BASE_FOLDER.join("parsed/test/factions/factionreputation_lawful_foxwellenforcement.json")))

        faction = loader.one(data)
        assert_not faction.logo.attached?

        default_loader = loader
        default_loader.define_singleton_method(:default_environment?) { true }
        default_loader.one(data)

        assert faction.reload.logo.attached?
      end
    end
  end
end
