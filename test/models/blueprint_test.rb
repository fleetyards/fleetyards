# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: blueprints
#
#  id             :uuid             not null, primary key
#  category_ref   :string
#  craft_time     :integer
#  craftable_type :string
#  name           :string
#  sc_key         :string           not null
#  sc_ref         :string           not null
#  slot_count     :integer
#  slug           :string           not null
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  craftable_id   :uuid
#
# Indexes
#
#  index_blueprints_on_craftable_type_and_craftable_id  (craftable_type,craftable_id)
#  index_blueprints_on_sc_key                           (sc_key) UNIQUE
#  index_blueprints_on_sc_ref                           (sc_ref) UNIQUE
#  index_blueprints_on_slug                             (slug) UNIQUE
#  index_blueprints_on_version                          (version)
#
class BlueprintTest < ActiveSupport::TestCase
  # From the key rather than the name: three outputs carry two blueprints each
  # in 4.10.1, and two recipes for the same shield cannot share a URL.
  test "generates a slug from the record key" do
    blueprint = create(:blueprint, sc_key: "bp_craft_klwe_smg_energy_01")

    assert_equal "klwe-smg-energy-01", blueprint.slug
  end

  test "two recipes for the same output keep their own slugs" do
    component = create(:component)
    first = create(:blueprint, sc_key: "bp_craft_shld_s04_890jump", craftable: component)
    second = create(:blueprint, sc_key: "bp_craft_shld_s04_polaris", craftable: component)

    assert_not_equal first.slug, second.slug
    assert_equal [component, component], [first.craftable, second.craftable]
  end

  test "rejects a duplicate ref" do
    create(:blueprint, sc_ref: "beef")
    duplicate = build(:blueprint, sc_ref: "beef")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :sc_ref
  end

  # 28 of the 1607 recipes in 4.10.1 make something no catalogue here carries.
  test "loads without a craftable" do
    blueprint = create(:blueprint, :without_craftable, name: "Probe")

    assert_predicate blueprint, :valid?
    assert_nil blueprint.craftable
  end

  test "#current_version narrows to the build we are on" do
    current = create(:blueprint)
    retired = create(:blueprint, :without_build, version: nil)

    assert_includes Blueprint.current_version, current
    assert_not_includes Blueprint.current_version, retired
    assert_includes Blueprint.current_version(false), retired
  end

  test "#retired? is true for a recipe the build no longer carries" do
    assert_not_predicate create(:blueprint), :retired?
    assert_predicate create(:blueprint, :without_build, version: nil), :retired?
  end

  # The build is what a reader sees, so an admin correction to the row alone
  # must not silently win over what the load wrote.
  test "reads its facts through the build" do
    blueprint = create(:blueprint, name: "Row Name")
    blueprint.build.update!(name: "Build Name", craft_time: 300)

    assert_equal "Build Name", blueprint.reload.name
    assert_equal 300, blueprint.craft_time
  end

  test "falls back to the column where no build describes it" do
    blueprint = create(:blueprint, :without_build, name: "Row Name", version: nil)

    assert_equal "Row Name", blueprint.name
  end

  # A recipe naming the same material in two slots has to come back once.
  test ".consuming finds each recipe that uses a commodity once" do
    commodity = create(:commodity)
    blueprint = create(:blueprint)
    2.times do |position|
      slot = create(:blueprint_cost_slot, build: blueprint.build, position:)
      create(:blueprint_cost_option, slot:, commodity:)
    end
    create(:blueprint)

    assert_equal [blueprint], Blueprint.consuming(commodity).to_a
  end

  # Live and ptu are loaded separately and either can be read, so one global
  # recipe would leave whichever tree loaded last supplying the costs for both.
  test ".consuming ignores a recipe another build states" do
    commodity = create(:commodity)
    blueprint = create(:blueprint)
    other = blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1")
    create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: other), commodity:)

    assert_empty Blueprint.consuming(commodity)
    assert_empty blueprint.reload.cost_slots
  end

  test ".making finds the recipes for one output" do
    component = create(:component)
    blueprint = create(:blueprint, craftable: component)
    create(:blueprint, craftable: create(:component))

    assert_equal [blueprint], Blueprint.making(component).to_a
  end

  # The columns on the row carry whatever the last source to load wrote, so a
  # filter against them answers a ptu request with live's links.
  test ".making ignores an output only another build states" do
    component = create(:component)
    blueprint = create(:blueprint, :without_build, version: nil, craftable: component)
    blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1", craftable: component)

    assert_empty Blueprint.making(component)
  end

  test "#craftable comes from the build we are read for" do
    blueprint = create(:blueprint, craftable: create(:component))
    replacement = create(:equipment)
    blueprint.build.update!(craftable: replacement)

    assert_equal replacement, blueprint.reload.craftable
  end

  # A nil on the build is an answer, not a gap to fill from the row -- three
  # radars have no name in the game files at all, and falling back would have
  # served another source's name for them.
  test "a fact the build leaves empty does not fall back to the row" do
    blueprint = create(:blueprint, name: "Row Name")
    blueprint.build.update!(name: nil)

    assert_nil blueprint.reload.name
  end

  # 875 of the 1607 recipes in 4.10.1 are in no pool, and 26 more are only in a
  # pool nothing hands out. The page has to say so rather than render nothing.
  test "#source_unknown? is true where the export says nothing" do
    sourced = create(:blueprint)
    create(:blueprint_source, build: sourced.build)

    assert_not_predicate sourced.reload, :source_unknown?
    assert_predicate create(:blueprint), :source_unknown?
  end

  test ".with_known_source splits the catalogue both ways" do
    sourced = create(:blueprint)
    create(:blueprint_source, build: sourced.build)
    unsourced = create(:blueprint)

    assert_equal [sourced], Blueprint.with_known_source.to_a
    assert_equal [unsourced], Blueprint.with_known_source(false).to_a
  end

  test ".from_org finds each recipe an org hands out once" do
    blueprint = create(:blueprint)
    2.times { |n| create(:blueprint_source, build: blueprint.build, org_name: "Eckhart Security", position: n) }
    create(:blueprint_source, build: create(:blueprint).build, org_name: "Headhunters")

    assert_equal [blueprint], Blueprint.from_org("Eckhart Security").to_a
  end

  # Sources belong to the build for the reason the recipe does: live and ptu
  # are loaded separately and either can be read.
  test ".from_org ignores a source only another build states" do
    blueprint = create(:blueprint, :without_build, version: nil)
    other = blueprint.builds.create!(environment: "ptu", version: "9.9.9-ptu.1")
    create(:blueprint_source, build: other, org_name: "Eckhart Security")

    assert_empty Blueprint.from_org("Eckhart Security")
    assert_empty blueprint.reload.sources
  end

  # The row keeps its last build so a retired recipe still resolves. Reading the
  # recipe and the sources through the current build alone made a retired one
  # look like a recipe with no ingredients that nobody knows a source for.
  test "a retired recipe still carries its recipe and its sources" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Retired"
    )
    create(:blueprint_cost_slot, build: last)
    create(:blueprint_source, build: last, org_name: "Eckhart Security")
    # Something else has to carry the configured build. With nothing loaded at
    # it, `ScData::Source#served` falls back to the newest build there is --
    # which in a test that creates exactly one is the very build it means to
    # call retired.
    create(:blueprint, :without_build).builds.create!(
      environment: ScData::Source.environment, version: ScData::Source.version
    )

    blueprint.reload

    assert_predicate blueprint, :retired?
    assert_equal 1, blueprint.cost_slots.count
    assert_equal 1, blueprint.sources.count
    assert_not_predicate blueprint, :source_unknown?
  end

  test "a blueprint no build has ever described reads as empty rather than raising" do
    blueprint = create(:blueprint, :without_build, version: nil)

    assert_empty blueprint.cost_slots
    assert_empty blueprint.sources
    assert_empty blueprint.cost_options
    assert_predicate blueprint, :source_unknown?
  end

  test "#cost_options reaches the options of the build being read" do
    blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, build: blueprint.build)
    option = create(:blueprint_cost_option, slot:)

    assert_equal [option], blueprint.reload.cost_options.to_a
  end

  # A filter pinned to the current build while the render falls back drops a
  # retired recipe whose retained build does name the org being asked for.
  test ".from_org reaches the fallback build when the current one is gone" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_source, build: last, org_name: "Eckhart Security")

    assert_empty Blueprint.from_org("Eckhart Security")
    assert_equal [blueprint], Blueprint.from_org("Eckhart Security", ScData::Source.current, current_only: false).to_a
  end

  # And the same recipe must not read as sourceless under the fallback, which
  # would contradict its own rendered response.
  test ".with_known_source reaches the fallback build too" do
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_source, build: last)

    assert_equal [blueprint], Blueprint.with_known_source(true, ScData::Source.current, current_only: false).to_a
    assert_empty Blueprint.with_known_source(false, ScData::Source.current, current_only: false)
  end

  test ".consuming reaches the fallback build too" do
    commodity = create(:commodity)
    blueprint = create(:blueprint, :without_build, version: nil)
    last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
    create(:blueprint_cost_option, slot: create(:blueprint_cost_slot, build: last), commodity:)

    assert_empty Blueprint.consuming(commodity)
    assert_equal [blueprint], Blueprint.consuming(commodity, ScData::Source.current, current_only: false).to_a
  end

  test "destroying a blueprint takes its builds, recipes and sources with it" do
    blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, build: blueprint.build)
    create(:blueprint_cost_option, slot:)
    create(:blueprint_cost_modifier, slot:)

    create(:blueprint_source, build: blueprint.build)

    assert_difference -> { BlueprintBuild.count } => -1,
      -> { BlueprintCostSlot.count } => -1,
      -> { BlueprintCostOption.count } => -1,
      -> { BlueprintCostModifier.count } => -1,
      -> { BlueprintSource.count } => -1 do
      blueprint.destroy
    end
  end
end
