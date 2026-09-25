# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_vehicles
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fleet_id   :uuid
#  vehicle_id :uuid             not null
#
# Indexes
#
#  index_fleet_vehicles_on_fleet_id_and_vehicle_id  (fleet_id,vehicle_id) UNIQUE
#  index_fleet_vehicles_on_vehicle_id               (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_id => vehicles.id) ON DELETE => cascade
#
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
end
