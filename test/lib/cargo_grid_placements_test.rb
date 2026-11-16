# frozen_string_literal: true

require "test_helper"

class CargoGridPlacementsTest < ActiveSupport::TestCase
  QUARTER = [0.0, -Math.sqrt(0.5), 0.0, Math.sqrt(0.5)].freeze
  STRAIGHT = [0.0, 0.0, 0.0, 1.0].freeze

  private def grid(name, position:, rotation: QUARTER, size: [5.0, 5.0, 7.5])
    {"name" => name, "position" => position, "rotation" => rotation, "size" => size}
  end

  test "places a grid with the values its export gives it" do
    placements = CargoGridPlacements.call([
      grid("module", position: [0.625, -0.25, -2.625]),
      grid("nose", position: [-0.01, -0.8, -43.74], rotation: STRAIGHT, size: [6.25, 3.75, 5.0])
    ])

    assert_equal({"position" => [0.625, -0.25, -2.625], "orientation" => QUARTER, "size" => [5.0, 5.0, 7.5]}, placements["module"])
    assert_equal STRAIGHT, placements["nose"]["orientation"]
  end

  test "places nothing when a grid is tilted or turned by less than a quarter" do
    tilted = [Math.sqrt(0.5), 0.0, 0.0, Math.sqrt(0.5)]
    eighth = [0.0, Math.sin(Math::PI / 8), 0.0, Math.cos(Math::PI / 8)]

    [tilted, eighth].each do |rotation|
      assert_empty CargoGridPlacements.call([
        grid("module", position: [0.0, 0.0, 0.0]),
        grid("odd", position: [0.0, 0.0, 10.0], rotation:)
      ])
    end
  end

  test "names a grid on a nested port by both names a hold may carry" do
    placements = CargoGridPlacements.call([
      grid("cargo_grid", position: [0.0, -1.68, 4.74]).merge("parentPort" => "hardpoint_lift"),
      grid("hardpoint_cargo_grid_left", position: [-10.1, -0.5, 4.5]).merge("parentPort" => nil)
    ])

    assert_equal %w[cargo_grid hardpoint_cargo_grid_left hardpoint_lift-cargo_grid], placements.keys.sort
    assert_equal placements["cargo_grid"], placements["hardpoint_lift-cargo_grid"]
  end

  test "keeps a grid at the top on its name when a nested one shares it" do
    placements = CargoGridPlacements.call([
      grid("cargo_grid", position: [0.0, 0.0, 0.0]).merge("parentPort" => "hardpoint_lift"),
      grid("cargo_grid", position: [0.0, 0.0, 20.0])
    ])

    assert_not_equal placements["cargo_grid"], placements["hardpoint_lift-cargo_grid"]
  end

  test "places nothing for an export without grids" do
    assert_empty CargoGridPlacements.call(nil)
    assert_empty CargoGridPlacements.call([])
  end
end
