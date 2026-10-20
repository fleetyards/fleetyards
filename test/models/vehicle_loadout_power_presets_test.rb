# frozen_string_literal: true

require "test_helper"

class VehicleLoadoutPowerPresetsTest < ActiveSupport::TestCase
  setup do
    @loadout = create(:vehicle_loadout, :fleetyards)
  end

  def preset(name: "Dogfight", mode: "SCM", overrides: [{port_path: "hardpoint_shield", pips: 2}])
    {name:, mode:, overrides:}
  end

  test "keeps named splits with the loadout" do
    @loadout.update!(power_presets: [preset(name: " Dogfight "), preset(name: "Travel", mode: "NAV", overrides: [])])

    assert_equal(
      [
        {"name" => "Dogfight", "mode" => "SCM", "overrides" => [{"port_path" => "hardpoint_shield", "pips" => 2}]},
        {"name" => "Travel", "mode" => "NAV", "overrides" => []}
      ],
      @loadout.reload.power_presets
    )
  end

  test "refuses two presets of the same name" do
    @loadout.power_presets = [preset(name: "Dogfight"), preset(name: "dogfight")]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :name_taken)
  end

  test "refuses a preset without a name" do
    @loadout.power_presets = [preset(name: "  ")]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :name_blank)
  end

  test "refuses a flight mode the game does not have" do
    @loadout.power_presets = [preset(mode: "QT")]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :mode_invalid)
  end

  test "refuses negative or fractional pips" do
    [-1, 1.5, "2"].each do |pips|
      @loadout.power_presets = [preset(overrides: [{port_path: "hardpoint_shield", pips:}])]

      assert_not @loadout.valid?, "#{pips.inspect} pips were accepted"
      assert @loadout.errors.added?(:power_presets, :pips_invalid)
    end
  end

  test "refuses more presets than the limit" do
    @loadout.power_presets = (VehicleLoadout::MAX_POWER_PRESETS + 1).times.map { |index| preset(name: "Split #{index}") }

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :too_many, count: VehicleLoadout::MAX_POWER_PRESETS)
  end
end
