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
class FleetVehicle < ApplicationRecord
  paginates_per 30
  max_paginates_per 240
  per_page_steps [15, 30, 60, 120, 240, :all]

  belongs_to :fleet, touch: true
  belongs_to :vehicle

  validates :vehicle_id, uniqueness: {scope: [:fleet_id]}

  AVAILABLE_PRIVILEGES = [
    "fleet:vehicles:read",
    "fleet:vehicles:create",
    "fleet:vehicles:update",
    "fleet:vehicles:delete",
    "fleet:vehicles:manage"
  ].freeze

  DEFAULT_PRIVILEGES = {
    admin: [],
    officer: ["fleet:vehicles:manage"],
    member: ["fleet:vehicles:read"]
  }.freeze

  DEFAULT_SORTING_PARAMS = ["model_name asc"]
  ALLOWED_SORTING_PARAMS = [
    "model_name asc", "model_name desc", "created_at asc", "created_at desc", "updated_at asc",
    "updated_at desc"
  ]
end
