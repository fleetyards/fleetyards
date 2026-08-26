# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: equipment
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  equipment_type         :string
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  sc_key                 :string
#  sc_ref                 :string
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_on_equipment_type   (equipment_type)
#  index_equipment_on_item_type        (item_type)
#  index_equipment_on_manufacturer_id  (manufacturer_id)
#  index_equipment_on_sc_key           (sc_key) UNIQUE
#  index_equipment_on_slot             (slot)
#
class EquipmentTest < ActiveSupport::TestCase
  test "generates a slug from the name" do
    equipment = create(:equipment, name: "P4-AR Rifle")

    assert_equal "p4-ar-rifle", equipment.slug
  end

  test "requires a name" do
    equipment = build(:equipment, name: nil)

    assert_not equipment.valid?
    assert_includes equipment.errors.attribute_names, :name
  end

  test "rejects a duplicate sc_key" do
    create(:equipment, sc_key: "behr_rifle_ballistic_01")
    duplicate = build(:equipment, sc_key: "behr_rifle_ballistic_01")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :sc_key
  end

  test ".visible leaves out skins and dev copies" do
    shown = create(:equipment)
    create(:equipment, :hidden)

    assert_equal [shown.id], Equipment.visible.pluck(:id)
  end

  # A record the export dropped keeps the values of the last build that described
  # it -- an inventory entry pointing at one has to resolve to something -- and
  # says so, rather than serving them as if they were current.
  test "a retired record reads the last build that described it, and is marked" do
    equipment = create(:equipment, :without_build, name: "Column Name")
    create(
      :equipment_build,
      equipment:, environment: ScData::Source.environment,
      version: "0.0.1-live.1", name: "Behring P4-AR", size: "3"
    )

    assert_equal "Behring P4-AR", equipment.reload.name
    assert_equal "3", equipment.size
    assert_predicate equipment, :retired?
  end

  test "a record in the current build reads that build, and is not retired" do
    equipment = create(:equipment, :without_build, name: "Column Name")
    create(:equipment_build, equipment:, name: "Behring P4-AR")

    assert_equal "Behring P4-AR", equipment.reload.name
    assert_not_predicate equipment, :retired?
  end

  test "the current build wins over an earlier one" do
    equipment = create(:equipment, :without_build)
    create(:equipment_build, equipment:, version: "0.0.1-live.1", size: "1")
    create(:equipment_build, equipment:, size: "4")

    assert_equal "4", equipment.reload.size
  end

  # An admin can create a record by hand, and no load has given it a build yet.
  test "a record with no build at all falls back to its own columns" do
    equipment = create(:equipment, :without_build, name: "Hand Made", size: "2")

    assert_equal "Hand Made", equipment.reload.name
    assert_equal "2", equipment.size
    assert_predicate equipment, :retired?
  end

  # An enum-backed fact has to read as its name from the build too, not as the
  # integer the column stores.
  test "an enum fact read off the build keeps its name" do
    equipment = create(:equipment, :without_build)
    create(:equipment_build, equipment:, slot: :torso)

    assert_equal "torso", equipment.reload.slot
  end

  # Without this the reader would go on serving the build's old value.
  test "#update_with_facts writes the correction to the build as well" do
    equipment = create(:equipment, name: "Typo")

    assert equipment.update_with_facts({name: "Corrected"})

    assert_equal "Corrected", equipment.reload.name
    assert_equal "Corrected", equipment.build.name
  end

  test "#update_with_facts leaves a retired record's build alone" do
    equipment = create(:equipment, :without_build, name: "Typo")
    old = create(:equipment_build, equipment:, version: "0.0.1-live.1", name: "Old Name")

    assert equipment.update_with_facts({name: "Corrected"})

    assert_equal "Old Name", old.reload.name
  end

  test ".current_version narrows to the patch the game ships, or opts out" do
    current = create(:equipment)
    retired = create(:equipment, version: "0.0.1-live.1")

    assert_equal [current.id], Equipment.current_version.pluck(:id)
    assert_includes Equipment.current_version(false).pluck(:id), retired.id
  end

  test ".item_types leaves out types only older patches carried" do
    create(:equipment, item_type: "assault_rifle")
    create(:equipment, item_type: "toy_pistol", version: "0.0.1-live.1")

    assert_equal ["assault_rifle"], Equipment.item_types
  end

  test ".item_types lists what the visible rows carry" do
    create(:equipment, item_type: "assault_rifle")
    create(:equipment, item_type: "assault_rifle")
    create(:equipment, :attachment, item_type: "weapon_scope")
    create(:equipment, :hidden, item_type: "toy_pistol")

    assert_equal %w[assault_rifle weapon_scope], Equipment.item_types
  end

  test ".item_type_filters falls back to a humanised label without a translation" do
    create(:equipment, item_type: "newfangled_blaster")

    filter = Equipment.item_type_filters.find { |f| f.value == "newfangled_blaster" }

    assert_equal "Newfangled blaster", filter.label
    assert_equal "item_type", filter.category
  end

  # A class CIG adds between builds should load rather than raise, which is why
  # these are strings and not enums.
  test "accepts a weapon class the game files invent later" do
    equipment = build(:equipment, weapon_class: "plasma")

    assert_predicate equipment, :valid?
  end
end
