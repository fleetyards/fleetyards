# frozen_string_literal: true

require "test_helper"

class CargoGridPlacementsTest < ActiveSupport::TestCase
  QUARTER = [0.0, -Math.sqrt(0.5), 0.0, Math.sqrt(0.5)].freeze
  STRAIGHT = [0.0, 0.0, 0.0, 1.0].freeze

  # The Caterpillar's fourth module and its nose, as the export places them.
  private def grid(name, position:, rotation: QUARTER, dimensions: [5.0, 7.5, 5.0])
    {"name" => name, "position" => position, "rotation" => rotation, "dimensions" => dimensions}
  end

  private def relative(placements)
    mins = %w[x y z].to_h { |axis| [axis, placements.values.map { |placed| placed["offset"][axis] }.min] }

    placements.transform_values do |placed|
      %w[x y z].map { |axis| (placed["offset"][axis] - mins[axis]).round(2) }
    end
  end

  test "places a module's grids the way the tool lays them out by hand" do
    placements = CargoGridPlacements.call([
      grid("module", position: [0.625, -0.25, -2.625]),
      grid("walkway", position: [-3.75, -1.5, -2.625], dimensions: [5.0, 1.25, 2.5])
    ])

    assert_equal({"module" => [0.0, 1.25, 0.0], "walkway" => [0.0, 0.0, 0.0]}, relative(placements))
    assert_nil placements["module"]["rotation"]
  end

  test "turns a grid a quarter off the ship's modules" do
    placements = CargoGridPlacements.call([
      grid("nose", position: [-0.01, -0.8, -43.74], rotation: STRAIGHT, dimensions: [6.25, 5.0, 3.75])
    ])

    assert_equal 270, placements["nose"]["rotation"]
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

  test "places nothing for an export without grids" do
    assert_empty CargoGridPlacements.call(nil)
    assert_empty CargoGridPlacements.call([])
  end
end
