# frozen_string_literal: true

require "test_helper"

class FleetVehicleTest < ActiveSupport::TestCase
  should belong_to(:vehicle)
  should belong_to(:fleet)

  test ".model_sorts leaves the count sort to the grouped list" do
    assert_equal ["length desc"], FleetVehicle.model_sorts(["vehicles_count desc", "model_length desc"])
    assert_equal ["name asc"], FleetVehicle.model_sorts(["vehicles_count desc"])
  end

  test ".count_sort? recognises the count sort in either direction" do
    assert FleetVehicle.count_sort?("vehicles_count desc")
    assert FleetVehicle.count_sort?("vehicles_count asc")
    assert_not FleetVehicle.count_sort?("model_name asc")
  end

  test ".vehicle_sorts drops the count sort" do
    assert_equal ["model_length asc"], FleetVehicle.vehicle_sorts(["vehicles_count desc", "model_length asc"])
    assert_equal FleetVehicle::DEFAULT_SORTING_PARAMS, FleetVehicle.vehicle_sorts(["vehicles_count desc"])
  end

  # A grouped row is a ship, sorted by the most it can carry; a vehicle row by
  # what it carries as its owner shows it to the fleet.
  test "the cargo sort follows the figure each list shows" do
    assert_equal ["max_cargo desc"], FleetVehicle.model_sorts(["model_cargo desc"])
    assert_equal ["public_cargo desc"], FleetVehicle.vehicle_sorts(["model_cargo desc"])
  end
end
