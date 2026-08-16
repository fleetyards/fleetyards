# frozen_string_literal: true

require "test_helper"

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
