# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_vehicles
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  fleet_id   :uuid
#  vehicle_id :uuid
#
# Indexes
#
#  index_fleet_vehicles_on_fleet_id_and_vehicle_id  (fleet_id,vehicle_id) UNIQUE
#  index_fleet_vehicles_on_vehicle_id               (vehicle_id)
#
require "test_helper"

class FleetVehicleTest < ActiveSupport::TestCase
  should belong_to(:vehicle)
  should belong_to(:fleet)
end
