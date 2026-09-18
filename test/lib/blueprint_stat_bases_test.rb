# frozen_string_literal: true

require "test_helper"

class BlueprintStatBasesTest < ActiveSupport::TestCase
  test "reads a plain figure off a component's type data" do
    component = build(:component, type_data: {"max_health" => 3168.0})

    assert_in_delta 3168.0, BlueprintStatBases.new(component).for("gpp_shield_maxhealth")
  end

  # A weapon's damage is split across the types it deals, almost always with
  # one of them carrying the whole figure.
  test "sums a weapon's damage across the types it deals" do
    component = build(:component, type_data: {
      "damage_per_shot" => {"energy" => 350.0, "physical" => 25.0, "thermal" => 0.0}
    })

    assert_in_delta 375.0, BlueprintStatBases.new(component).for("gpp_weapon_damage")
  end

  test "says nothing for a stat the catalogue holds no figure for" do
    component = build(:component, type_data: {"max_health" => 10.0})

    assert_nil BlueprintStatBases.new(component).for("gpp_health_maxhealth")
    assert_nil BlueprintStatBases.new(component).for("gpp_weapon_recoil_kick")
  end

  test "reads a column off equipment" do
    equipment = build(:equipment, damage_reduction: 30)

    assert_in_delta 30.0, BlueprintStatBases.new(equipment).for("gpp_armor_damagemitigation")
  end

  # Armour states its band as one rendered string rather than as two columns.
  test "splits armour's temperature band into its two ends" do
    equipment = build(:equipment, temperature_rating: "-56 / 86 °C")
    bases = BlueprintStatBases.new(equipment)

    assert_in_delta(-56.0, bases.for("gpp_armor_temperaturemin"))
    assert_in_delta 86.0, bases.for("gpp_armor_temperaturemax")
  end

  # 15 of the 850 bands in the build omit the degree sign.
  test "splits a temperature band written without a degree sign" do
    equipment = build(:equipment, temperature_rating: "-61 / 91 C")

    assert_in_delta 91.0, BlueprintStatBases.new(equipment).for("gpp_armor_temperaturemax")
  end

  test "says nothing for a band it cannot read" do
    equipment = build(:equipment, temperature_rating: "chilly")

    assert_nil BlueprintStatBases.new(equipment).for("gpp_armor_temperaturemin")
  end

  # 5 of the 1,607 recipes make something no catalogue here carries.
  test "says nothing when the recipe makes nothing we hold" do
    assert_nil BlueprintStatBases.new(nil).for("gpp_shield_maxhealth")
  end
end
