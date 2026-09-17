# frozen_string_literal: true

require "test_helper"

module ScData
  module Loader
    class BlueprintsLoaderTest < ActiveSupport::TestCase
      IRON_KEY = "items_commodities_iron"
      OUTPUT_REF = "75809555-848a-4f4d-81a0-db4457edba2d"
      SECOND_REF = "a39d0aa5-f1af-49fb-aad0-0c1cde0f133f"

      # A blueprint the Foxwell Enforcement ambush pool actually hands out, so
      # the source side resolves against the real tree the way the output side
      # already does.
      POOLED_REF = "6157c081-0a9b-4319-bbbc-7f2cc1ef7158"

      setup do
        Blueprint.delete_all
        @loader = ::ScData::Loader::BlueprintsLoader.new
      end

      # One full load, asserted from every angle. A load writes 1,607 records
      # with 15k recipe rows and 4k sources, and the suite pays for it twice
      # over -- once to write it and again to roll it back -- so the
      # assertions are gathered here rather than each buying their own load.
      test "#all loads the catalogue, its builds, its recipes and its sources" do
        @loader.all

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

        # 875 recipes appear in no pool and 26 more only in a pool nothing
        # hands out, so most of the catalogue has no stated source at all.
        assert_operator Blueprint.with_known_source.count, :>=, 600
        assert_operator Blueprint.with_known_source(false).count, :>=, 800
      end

      # Three outputs carry two blueprints each in 4.10.1 -- the 890 Jump and
      # Polaris S04 shields, two S01 quantum drives and two S02 powerplants --
      # which a unique index on the output would have failed the load on.
      test "#one keeps both recipes where two make the same thing" do
        component = create(:component, sc_ref: OUTPUT_REF)

        first = @loader.one(blueprint_data)
        second = @loader.one(blueprint_data.merge("key" => "bp_craft_example_two", "ref" => SECOND_REF))

        assert_not_equal first, second
        assert_equal [component, component], [first.craftable, second.craftable]
      end

      test "#all is idempotent" do
        @loader.all

        counts = -> { [Blueprint.count, BlueprintCostSlot.count, BlueprintCostOption.count, BlueprintCostModifier.count] }
        before = counts.call

        @loader.all

        assert_equal before, counts.call
      end

      # A recipe the export dropped keeps its row -- nothing should break for a
      # reader holding a link to it -- but it must stop claiming the build.
      test "#all retires a blueprint the export no longer carries" do
        retired = create(:blueprint, sc_key: "bp_craft_gone", version: ScData::Source.version)

        @loader.all

        assert_nil retired.reload.version
        assert_predicate retired, :retired?
      end

      test "#one links a component output by its ref" do
        component = create(:component, sc_ref: OUTPUT_REF, name: "Yubarev Pistol")

        blueprint = @loader.one(blueprint_data(kind: "Component"))

        assert_equal component, blueprint.craftable
        assert_equal "Yubarev Pistol", blueprint.name
        assert_equal component, blueprint.build.craftable
      end

      # `Commodity#sc_ref` comes from the crate entity and is null for 100 of
      # the 232 rows, Iron included, so a commodity output joins on its key.
      test "#one links a commodity output by its key rather than its ref" do
        commodity = create(:commodity, sc_key: IRON_KEY, sc_ref: nil, name: "Iron")

        blueprint = @loader.one(blueprint_data(kind: "Commodity", commodity_key: IRON_KEY))

        assert_equal commodity, blueprint.craftable
      end

      # 28 of the 1607 recipes in 4.10.1 make something no catalogue here
      # carries. They still have to load, and they still have to have a name.
      test "#one loads a recipe whose output is in no catalogue" do
        blueprint = @loader.one(blueprint_data(kind: "Commodity", commodity_key: nil, output_name: "Probe"))

        assert_nil blueprint.craftable
        assert_equal "Probe", blueprint.name
        assert_predicate blueprint, :persisted?
      end

      test "#one resolves a cost option to its commodity" do
        commodity = create(:commodity, sc_key: IRON_KEY, name: "Iron")

        blueprint = @loader.one(blueprint_data)
        option = blueprint.build.cost_slots.first.options.first

        assert_equal commodity, option.commodity
        assert_equal IRON_KEY, option.commodity_key
        assert_equal "resource", option.cost_type
        assert_in_delta 0.03, option.quantity
      end

      # A material the commodity catalogue has no row for must not take the
      # recipe down with it, and the line still has to say which material.
      test "#one keeps a cost option whose commodity is missing" do
        blueprint = @loader.one(blueprint_data(commodity_key: "items_commodities_unknown"))
        option = blueprint.build.cost_slots.first.options.first

        assert_nil option.commodity
        assert_equal "items_commodities_unknown", option.commodity_key
      end

      # The recipe is rewritten wholesale on each run, so a slot CIG removed has
      # to disappear rather than linger beside the ones that replaced it.
      test "#one replaces the recipe rather than adding to it" do
        @loader.one(blueprint_data(slots: 3))

        assert_equal 3, BlueprintCostSlot.count

        @loader.one(blueprint_data(slots: 1))

        assert_equal 1, BlueprintCostSlot.count
        assert_equal 1, BlueprintCostOption.count
      end

      # Live and ptu are loaded separately and a reader can be pointed at
      # either, so a recipe shared between them would leave whichever tree
      # loaded last supplying the costs for both.
      test "#one leaves another source's recipe alone" do
        blueprint = @loader.one(blueprint_data(slots: 2))
        live = blueprint.build

        ptu = ::ScData::Loader::BlueprintsLoader.new
        ptu.sc_environment = "ptu"
        ptu.sc_version = "9.9.9-ptu.1"
        ptu.one(blueprint_data(slots: 1))

        assert_equal 2, live.reload.cost_slots.count
        assert_equal 3, BlueprintCostSlot.count
      end

      # The recipe belongs to the build, and both `retire_absent_builds` and
      # `prune_builds` drop a build with `delete_all` -- which skips
      # `dependent: :destroy` entirely. Only the foreign key's cascade takes the
      # recipe with it, so that is what this asserts.
      test "dropping a build takes its recipe with it" do
        blueprint = create(:blueprint)
        slot = create(:blueprint_cost_slot, build: blueprint.build)
        create(:blueprint_cost_option, slot:)
        create(:blueprint_cost_modifier, slot:)

        @loader.retire_absent_builds(BlueprintBuild, :blueprint_id, [create(:blueprint).id])

        assert_equal 0, BlueprintCostSlot.where(id: slot.id).count
        assert_equal 0, BlueprintCostOption.where(blueprint_cost_slot_id: slot.id).count
        assert_equal 0, BlueprintCostModifier.where(blueprint_cost_slot_id: slot.id).count
      end

      test "#one keeps every segment of a piecewise ramp" do
        blueprint = @loader.one(blueprint_data(ranges: [[0, 499], [500, 1000]]))
        modifiers = blueprint.build.cost_slots.first.modifiers

        assert_equal 2, modifiers.size
        assert_equal [499, 1000], modifiers.map(&:end_quality)
      end

      # --- sources ------------------------------------------------------

      test "#one writes the org, the mission and the standing band" do
        blueprint = @loader.one(blueprint_data(ref: POOLED_REF))
        source = blueprint.build.sources.first

        assert_equal "contract", source.kind
        assert_predicate source, :attributed?
        assert source.mission_name.present?
        assert source.min_standing.present?
      end

      # A pool is named by every difficulty of every mission that hands it out,
      # so the same entry arrives several times and the page would otherwise
      # list one line per repetition.
      #
      # Deduplicated on the whole tuple rather than on the mission, because a
      # title is reused across bands: Foxwell's "Orange Level Contract: Return
      # the Favor" is offered both Sr.-to-Head and Sr.-to-Elite, and those are
      # two real offers rather than one row written twice.
      test "#one writes each distinct source once" do
        blueprint = @loader.one(blueprint_data(ref: POOLED_REF))
        sources = blueprint.build.sources.map do |source|
          [source.kind, source.org_name, source.mission_name, source.pool_sc_ref,
            source.min_standing, source.max_standing, source.min_points]
        end

        assert_equal sources.uniq.size, sources.size
        assert_operator sources.size, :>, 1
      end

      test "#one leaves a blueprint no pool names without sources" do
        blueprint = @loader.one(blueprint_data)

        assert_empty blueprint.build.sources
        assert_predicate blueprint.reload, :source_unknown?
      end

      # Sources are rewritten with the build, the way the recipe is.
      test "#one replaces the sources rather than adding to them" do
        blueprint = @loader.one(blueprint_data(ref: POOLED_REF))
        count = blueprint.build.sources.count

        assert_operator count, :>, 0

        @loader.one(blueprint_data(ref: POOLED_REF))

        assert_equal count, blueprint.build.reload.sources.count
      end

      test "dropping a build takes its sources with it" do
        blueprint = create(:blueprint)
        source = create(:blueprint_source, build: blueprint.build)

        @loader.retire_absent_builds(BlueprintBuild, :blueprint_id, [create(:blueprint).id])

        assert_equal 0, BlueprintSource.where(id: source.id).count
      end

      private def blueprint_data(kind: "Component", commodity_key: IRON_KEY, output_name: nil,
        slots: 1, ranges: [[0, 1000]], ref: OUTPUT_REF)
        {
          "key" => "bp_craft_example",
          "ref" => ref,
          "category_ref" => "beef",
          "craft_time" => 120,
          "slot_count" => 3,
          "output" => {
            "ref" => OUTPUT_REF,
            "kind" => kind,
            "name" => output_name,
            "commodity_key" => (commodity_key if kind == "Commodity")
          }.compact,
          "slots" => Array.new(slots) { |position| slot_data(position, commodity_key, ranges) }
        }.with_indifferent_access
      end

      private def slot_data(position, commodity_key, ranges)
        {
          "position" => position,
          "key" => "frame",
          "name" => "Frame",
          "options" => [
            {
              "position" => 0,
              "cost_type" => "resource",
              "commodity_key" => commodity_key,
              "quantity" => 0.03,
              "min_quality" => 0
            }
          ],
          "modifiers" => ranges.each_with_index.map do |(from, to), index|
            {
              "position" => index,
              "ramp" => "linear",
              "property_ref" => "cafe",
              "property_key" => "gpp_weapon_damage",
              "name" => "Impact Force",
              "unit_format" => "%+.2f %%",
              "start_quality" => from,
              "end_quality" => to,
              "modifier_at_start" => 0.95,
              "modifier_at_end" => 1.05
            }
          end
        }
      end
    end
  end
end
