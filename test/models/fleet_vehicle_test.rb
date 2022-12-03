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
require 'test_helper'

class FleetVehicleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
