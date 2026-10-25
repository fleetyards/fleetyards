# frozen_string_literal: true

require "test_helper"

# The cases `craftedComponent.spec.ts` checks the browser's crafting against.
class CraftedFiguresTest < ActiveSupport::TestCase
  Slot = Struct.new(:position, :modifiers)
  Modifier = Struct.new(:property_key, :name, :ramp, :start_quality, :end_quality, :modifier_at_start, :modifier_at_end)

  def modifier(key, ramp: "linear", from: 0, to: 1000, low: 0.8, high: 1.2)
    Modifier.new(key, key, ramp, from, to, low, high)
  end

  test "multiplies two slots moving the same stat" do
    figures = CraftedFigures.new(
      [Slot.new(0, [modifier("gpp_shield_maxhealth")]), Slot.new(1, [modifier("gpp_shield_maxhealth")])],
      {"0" => 1000, "1" => 1000}
    )

    assert_in_delta 1.44, figures.changes["gpp_shield_maxhealth"].value
  end

  test "skips a modifier that carries no figures" do
    figures = CraftedFigures.new([Slot.new(0, [modifier("gpp_itemresource_powergeneration", low: nil, high: nil)])], {"0" => 1000})

    assert_empty figures.changes
  end

  test "reads as the catalogue's part at the neutral grade" do
    figures = CraftedFigures.new([Slot.new(0, [modifier("gpp_shield_maxhealth")])], {})

    assert_equal({"max_health" => 1000.0, "max_regen" => 100}, figures.type_data({"max_health" => 1000, "max_regen" => 100}))
  end

  test "scales a gun's damage of every type alike" do
    figures = CraftedFigures.new([Slot.new(0, [modifier("gpp_weapon_damage")])], {"0" => 1000})

    assert_equal({"energy" => 12.0, "physical" => 6.0},
      figures.type_data({"damage_per_shot" => {"energy" => 10, "physical" => 5}})["damage_per_shot"])
  end

  test "adds whole pips to a power plant, rounding halves up below zero too" do
    lose = CraftedFigures.new([Slot.new(0, [modifier("gpp_itemresource_powergeneration", ramp: "linear_integer_additive", low: -2.5, high: -2.5)])], {"0" => 0})

    assert_equal 8, lose.type_data({"power_base" => 10})["power_base"]
  end

  test "holds a piecewise ramp's end value past its domain" do
    figures = CraftedFigures.new(
      [Slot.new(0, [modifier("gpp_shield_maxhealth", from: 0, to: 500, low: 0.9, high: 1.0), modifier("gpp_shield_maxhealth", from: 500, to: 800, low: 1.0, high: 1.3)])],
      {"0" => 950}
    )

    assert_in_delta 1.3, figures.changes["gpp_shield_maxhealth"].value
  end
end
