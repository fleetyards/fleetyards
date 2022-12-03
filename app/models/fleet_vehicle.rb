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
class FleetVehicle < ApplicationRecord
  belongs_to :fleet, touch: true
  belongs_to :vehicle
end
