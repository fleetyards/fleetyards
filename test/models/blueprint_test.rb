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
      slot = create(:blueprint_cost_slot, blueprint:, position:)
      create(:blueprint_cost_option, slot:, commodity:)
    end
    create(:blueprint)

    assert_equal [blueprint], Blueprint.consuming(commodity).to_a
  end

  test ".making finds the recipes for one output" do
    component = create(:component)
    blueprint = create(:blueprint, craftable: component)
    create(:blueprint, craftable: create(:component))

    assert_equal [blueprint], Blueprint.making(component).to_a
  end

  test "destroying a blueprint takes its recipe with it" do
    blueprint = create(:blueprint)
    slot = create(:blueprint_cost_slot, blueprint:)
    create(:blueprint_cost_option, slot:)
    create(:blueprint_cost_modifier, slot:)

    assert_difference -> { BlueprintCostSlot.count } => -1,
      -> { BlueprintCostOption.count } => -1,
      -> { BlueprintCostModifier.count } => -1 do
      blueprint.destroy
    end
  end
end
