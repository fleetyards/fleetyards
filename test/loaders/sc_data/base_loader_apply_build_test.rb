# frozen_string_literal: true

require "test_helper"

# Dual-writing: the loader puts its values on the row and on what this build says
# about the row, so reads can move to the build one catalogue at a time rather
# than in a single cut.
module ScData
  module Loader
    class BaseLoaderApplyBuildTest < ActiveSupport::TestCase
      setup do
        @loader = ::ScData::Loader::BaseLoader.new
        @equipment = create(:equipment)
      end

      test "#apply_build records the build the current environment is on" do
        @loader.apply_build(@equipment, {name: "Behring P4-AR"})

        build = @equipment.reload.build
        assert_equal "Behring P4-AR", build.name
        assert_equal ::ScData::Source.environment, build.environment
        assert_equal ::ScData::Source.version, build.version
      end

      # Keyed on the build, so re-loading the one we are on updates it in place
      # rather than piling up rows.
      test "#apply_build updates the build in place when it is reloaded" do
        @loader.apply_build(@equipment, {name: "First"})

        assert_difference("EquipmentBuild.count", 0) do
          @loader.apply_build(@equipment, {name: "Second"})
        end

        assert_equal "Second", @equipment.reload.build.name
      end

      # A new build lands beside its predecessor -- which is what makes a patch
      # diffable against the one before it.
      test "#apply_build leaves the previous build standing" do
        previous = create(
          :equipment_build,
          equipment: @equipment, environment: ::ScData::Source.environment, version: "4.8.0-live.1"
        )

        @loader.apply_build(@equipment, {name: "Behring P4-AR"})

        assert EquipmentBuild.exists?(previous.id)
        assert_equal 2, @equipment.reload.builds.count
        assert_equal ::ScData::Source.version, @equipment.build.version
      end

      # Bounded on purpose: history is worth a couple of patches, not every patch
      # ever shipped.
      test "#prune_builds keeps the retained builds and drops the rest" do
        keep = EquipmentBuild::BUILDS_RETAINED

        (keep + 2).times do |index|
          create(
            :equipment_build,
            equipment: create(:equipment),
            environment: ::ScData::Source.environment,
            version: "4.#{index}.0-live.#{index}",
            created_at: index.days.from_now
          )
        end

        @loader.prune_builds(EquipmentBuild)

        assert_equal keep, EquipmentBuild.distinct.count(:version)
      end

      # `where.not(version: [])` is `1=1`, so an environment with nothing loaded
      # must not have its history swept.
      test "#prune_builds leaves another environment's history alone" do
        create(:equipment_build, environment: "somewhere-else", version: "4.9.0-else.1")

        @loader.prune_builds(EquipmentBuild)

        assert_equal 1, EquipmentBuild.where(environment: "somewhere-else").count
      end

      test "#apply_build counts through the same stats as any other write" do
        @loader.apply_build(@equipment, {name: "Behring P4-AR"})

        assert_equal 1, @loader.stats["EquipmentBuild"][:created]
      end

      # The loader writes both, and they agree.
      test "the equipment loader writes the row and the build together" do
        data = {
          "key" => "behr_rifle_ballistic_01",
          "name" => "Behring P4-AR",
          "equipment_type" => "weapon",
          "item_type" => "assault_rifle",
          "size" => "2"
        }

        equipment = ::ScData::Loader::EquipmentLoader.new.one(data)

        assert_equal "Behring P4-AR", equipment.name
        assert_equal "Behring P4-AR", equipment.build.name
        assert_equal "weapon", equipment.build.equipment_type
        assert_equal ::ScData::Source.version, equipment.build.version
      end

      # sc_key identifies the item rather than describing a build, so it is not
      # repeated onto the build row.
      test "identity stays off the build" do
        equipment = ::ScData::Loader::EquipmentLoader.new.one({
          "key" => "behr_rifle_ballistic_01", "name" => "Behring P4-AR"
        })

        assert_equal "behr_rifle_ballistic_01", equipment.sc_key
        refute EquipmentBuild.column_names.include?("sc_key")
      end
    end
  end
end
