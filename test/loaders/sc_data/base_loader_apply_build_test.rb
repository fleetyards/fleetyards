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
        @equipment = create(:equipment, :without_build)
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

      # Without this, a record the export dropped keeps its row for the build it
      # is no longer part of -- and asking "is this in the current build?" by row
      # existence would answer yes.
      test "#retire_absent_builds drops the current build's row for a record the run did not load" do
        kept = create(:equipment, :without_build)
        dropped = create(:equipment, :without_build)
        @loader.apply_build(kept, {name: "Kept"})
        @loader.apply_build(dropped, {name: "Dropped"})

        @loader.retire_absent_builds(EquipmentBuild, :equipment_id, [kept.id])

        assert_predicate kept.reload.build, :present?
        assert_nil dropped.reload.build
        assert Equipment.exists?(dropped.id), "the row itself has to stay"
      end

      # An earlier build is history, not something this run reconciles.
      test "#retire_absent_builds leaves an earlier build alone" do
        equipment = create(:equipment, :without_build)
        earlier = create(
          :equipment_build,
          equipment:, environment: ::ScData::Source.environment, version: "4.8.0-live.1"
        )

        @loader.retire_absent_builds(EquipmentBuild, :equipment_id, [create(:equipment, :without_build).id])

        assert EquipmentBuild.exists?(earlier.id)
      end

      # `where.not(id: [])` is `1=1`, so a run that loaded nothing must not empty
      # the build it was going to write.
      test "#retire_absent_builds retires nothing when the run loaded nothing" do
        @loader.apply_build(@equipment, {name: "Behring P4-AR"})

        assert_equal 0, @loader.retire_absent_builds(EquipmentBuild, :equipment_id, [])
        assert_predicate @equipment.reload.build, :present?
      end

      # Bounded on purpose: history is worth a couple of patches, not every patch
      # ever shipped.
      test "#prune_builds keeps the retained builds and drops the rest" do
        keep = EquipmentBuild::BUILDS_RETAINED

        (keep + 2).times do |index|
          create(
            :equipment_build,
            equipment: create(:equipment, :without_build),
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

      # The same helper, the second catalogue. Components differ from equipment in
      # being referenced -- hardpoints, paints and modules carry a component_id --
      # so this also pins that the build lands beside the identity row rather than
      # replacing it.
      test "#apply_build works the same for a component" do
        component = create(:component, :without_build)

        @loader.apply_build(component, {name: "Gorgon", component_class: "Shield"})

        build = component.builds.sole
        assert_equal "Gorgon", build.name
        assert_equal "Shield", build.component_class
        assert_equal ::ScData::Source.environment, build.environment
        assert_equal ::ScData::Source.version, build.version
      end

      test "#retire_absent_builds drops a component's current build but keeps the component" do
        kept = create(:component, :without_build)
        dropped = create(:component, :without_build)
        create(:component_build, component: kept)
        create(:component_build, component: dropped)

        @loader.retire_absent_builds(ComponentBuild, :component_id, [kept.id])

        assert_equal 1, ComponentBuild.current.count
        assert Component.exists?(dropped.id), "the row itself has to stay"
        assert_empty dropped.builds.current
      end

      # The same helper, the third catalogue. Commodities are the simplest of the
      # three -- three facts, no enums, no serialized columns, no manufacturer --
      # so what this pins is that the loader writes only what a build says: the
      # identity keys and the UEX mapping stay on the row.
      test "#apply_build works the same for a commodity" do
        commodity = create(:commodity, :without_build)

        @loader.apply_build(commodity, {name: "Quantanium", commodity_type: "mineral"})

        build = commodity.builds.sole
        assert_equal "Quantanium", build.name
        assert_equal "mineral", build.commodity_type
        assert_equal ::ScData::Source.environment, build.environment
        assert_equal ::ScData::Source.version, build.version
      end

      test "a commodity build carries no identity or UEX columns to write to" do
        %w[sc_key sc_ref slug uex_id uex_code].each do |column|
          refute_includes CommodityBuild.column_names, column
        end
      end

      test "#retire_absent_builds drops a commodity's current build but keeps the commodity" do
        kept = create(:commodity, :without_build)
        dropped = create(:commodity, :without_build)
        create(:commodity_build, commodity: kept)
        create(:commodity_build, commodity: dropped)

        @loader.retire_absent_builds(CommodityBuild, :commodity_id, [kept.id])

        assert_equal 1, CommodityBuild.current.count
        assert Commodity.exists?(dropped.id), "the row itself has to stay"
        assert_empty dropped.builds.current
      end

      # The same helper, the fourth catalogue and the awkward one. Models carry
      # three sources rather than one -- the game files, the RSI ship matrix in
      # the `rsi_*` columns, and whatever an admin curated -- so what this pins is
      # the boundary: a build holds the mechanics the game files describe, and
      # nothing from the other two.
      test "#apply_build works the same for a model" do
        model = create(:model)

        @loader.apply_build(model, {mass: 1_234.5, scm_speed: 210.0, ground: true})

        build = model.builds.sole
        assert_equal 1_234.5, build.mass
        assert_equal 210.0, build.scm_speed
        assert_predicate build, :ground
        assert_equal ::ScData::Source.environment, build.environment
        assert_equal ::ScData::Source.version, build.version
      end

      # The five YAML columns through the helper rather than the factory, because
      # the loader hands it real structures and a coder missing on either side
      # turns one into a string somewhere in between.
      test "#apply_build round-trips a model's serialized facts" do
        model = create(:model)
        cargo_holds = [{"capacity" => 6, "dimensions" => {"x" => 1.25}}]
        refuel_boom = {"name" => "refuel_boom", "rate" => 5.0}

        @loader.apply_build(model, {cargo_holds:, refuel_boom:})

        build = model.builds.sole.reload
        assert_equal cargo_holds, build.cargo_holds
        assert_equal refuel_boom, build.refuel_boom
      end

      # `update_reason` is an `attr_accessor` for paper_trail's meta rather than a
      # column, so the loader has to keep it off the build -- and `FACTS` is what
      # does that.
      test "a model build has nowhere to put the loader's update reason" do
        refute_includes ModelBuild.column_names, "update_reason"
        refute_includes ModelBuild::FACTS, :update_reason
      end

      test "#retire_absent_builds drops a model's current build but keeps the model" do
        kept = create(:model)
        dropped = create(:model)
        create(:model_build, model: kept)
        create(:model_build, model: dropped)

        @loader.retire_absent_builds(ModelBuild, :model_id, [kept.id])

        assert_equal 1, ModelBuild.current.count
        assert Model.exists?(dropped.id), "the row itself has to stay"
        assert_empty dropped.builds.current
      end
    end
  end
end
