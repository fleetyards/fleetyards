# frozen_string_literal: true

require "test_helper"

class VehicleLoadoutPowerPresetsTest < ActiveSupport::TestCase
  setup do
    @loadout = create(:vehicle_loadout, :fleetyards)
  end

  def preset(name: "Dogfight", scm: [{port_path: "hardpoint_shield", pips: 2}], nav: [])
    {name:, scm:, nav:}
  end

  test "keeps named splits for both flight modes with the loadout" do
    @loadout.update!(power_presets: [
      preset(name: " Dogfight "),
      preset(name: "Travel", scm: [], nav: [{port_path: "hardpoint_quantum_drive", pips: 3}])
    ])

    assert_equal(
      [
        {"name" => "Dogfight", "scm" => [{"port_path" => "hardpoint_shield", "pips" => 2}], "nav" => []},
        {"name" => "Travel", "scm" => [], "nav" => [{"port_path" => "hardpoint_quantum_drive", "pips" => 3}]}
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

  test "refuses negative or fractional pips in either mode" do
    [{scm: [{port_path: "hardpoint_shield", pips: -1}]}, {nav: [{port_path: "hardpoint_shield", pips: 1.5}]}, {scm: [{port_path: "hardpoint_shield", pips: "2"}]}].each do |split|
      @loadout.power_presets = [preset(**split)]

      assert_not @loadout.valid?, "#{split.inspect} was accepted"
      assert @loadout.errors.added?(:power_presets, :pips_invalid)
    end
  end

  test "refuses a name longer than forty characters" do
    @loadout.power_presets = [preset(name: "x" * 41)]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :name_too_long, count: 40)
  end

  test "refuses more pips than a port takes" do
    @loadout.power_presets = [preset(scm: [{port_path: "hardpoint_shield", pips: 101}])]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :pips_invalid)
  end

  test "refuses a port set twice in one mode" do
    @loadout.power_presets = [preset(scm: [{port_path: "hardpoint_shield", pips: 1}, {port_path: "hardpoint_shield", pips: 2}])]

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :port_repeated)
  end

  test "keeps no presets with a linked loadout" do
    linked = create(:vehicle_loadout)
    linked.power_presets = [preset]

    assert_not linked.valid?
    assert linked.errors.added?(:power_presets, :not_fleetyards)
  end

  test "refuses more than five presets" do
    @loadout.power_presets = 6.times.map { |index| preset(name: "Split #{index}") }

    assert_not @loadout.valid?
    assert @loadout.errors.added?(:power_presets, :too_many, count: 5)
  end
end
