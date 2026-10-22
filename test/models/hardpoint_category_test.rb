# frozen_string_literal: true

require "test_helper"

class HardpointCategoryTest < ActiveSupport::TestCase
  setup do
    @model = create(:model)
  end

  private def hardpoint(sc_name, component: nil)
    Hardpoint.create!(parent: @model, sc_name:, source: :game_files, component:)
  end

  test "an empty paint slot is a paint slot by its name" do
    %w[hardpoint_paint hardpoint_paint_seat hardpoint_paint_trim].each do |sc_name|
      assert_equal "paints", hardpoint(sc_name).category, sc_name
    end
  end

  test "a component fitted in a paint slot keeps deciding the category" do
    fitted = create(:component, category: "utility", component_type: "Misc")

    assert_equal "utility", hardpoint("hardpoint_paint", component: fitted).category
  end

  test "a slot without a component and without a telling name stays unknown" do
    assert_equal "unknown", hardpoint("hardpoint_whatever").category
  end

  test "a part is filed by what it does where its component's category is broader" do
    {
      ["WeaponMining", "weapons"] => "mining_lasers",
      ["MiningModifier", "utility"] => "mining_modules",
      ["SalvageHead", "utility"] => "salvage_heads",
      ["SalvageModifier", "utility"] => "salvage_modules",
      ["TractorBeam", "weapons"] => "tractor_beams",
      ["TowingBeam", "weapons"] => "tractor_beams",
      ["Missile", "weapons"] => "missiles",
      ["Bomb", "weapons"] => "bombs",
      ["WeaponGun", "weapons"] => "weapons"
    }.each do |(component_type, category), expected|
      component = part(component_type, category, sc_key: ("salvage_head_standard" if component_type == "SalvageHead"))

      assert_equal expected, hardpoint("hardpoint_#{component_type.underscore}", component:).category, component_type
    end
  end

  test "mining, salvage and tractor parts leave the weapon group" do
    {"WeaponMining" => "mining", "SalvageHead" => "salvage", "TractorBeam" => "auxiliary"}.each do |component_type, group|
      component = part(component_type, "weapons", sc_key: ("salvage_head_standard" if component_type == "SalvageHead"))

      assert_equal group, hardpoint("hardpoint_#{component_type.underscore}", component:).group, component_type
    end
  end

  private def part(component_type, category, sc_key: nil)
    create(:component, component_type:, category:, sc_key: sc_key || "#{component_type.underscore}_#{SecureRandom.hex(3)}")
  end

  private def turret(*carried)
    turret = Hardpoint.new(parent: @model, sc_name: "hardpoint_turret_#{SecureRandom.hex(3)}", source: :game_files, component: part("Turret", "turret"))
    turret.carried_components = carried
    turret.save!
    turret
  end

  test "a turret is filed by what it carries" do
    assert_equal "salvage", turret(part("SalvageHead", "utility", sc_key: "salvage_head_standard")).group
    assert_equal "mining", turret(part("WeaponMining", "weapons")).group
    assert_equal "auxiliary", turret(part("TractorBeam", "weapons")).group
  end

  test "a tool arm that holds only the disintegration intake is salvage" do
    assert_equal "salvage", turret(part("SalvageFieldEmitter", "salvagemunching")).group
  end

  test "a disintegration intake on the hull stays out of the salvage group" do
    intake = part("SalvageFieldEmitter", "salvagemunching")

    assert_equal "unknown", hardpoint("hardpoint_disintegration_intake", component: intake).group
  end

  test "a turret that also carries a gun stays a weapon" do
    assert_equal "weapon", turret(part("TractorBeam", "weapons"), part("WeaponGun", "weapons")).group
  end

  test "a tractor beam the game files type as a salvage head is a tractor beam" do
    beam = part("SalvageHead", "utility", sc_key: "grin_tractorbeam_s3")

    assert_equal "tractor_beams", hardpoint("hardpoint_beam", component: beam).category
    assert_equal "auxiliary", turret(beam).group
  end
end
