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
  MODEL_SORT_FIELDS = %w[
    modelName modelManufacturerName modelLength modelBeam modelHeight modelMass modelCargo
    modelScmSpeed modelMaxSpeed modelGroundMaxSpeed modelFocus modelProductionStatus modelPrice
    modelPledgePrice
  ].freeze
  ALLOWED_SORTING_PARAMS = (MODEL_SORT_FIELDS + %w[createdAt updatedAt])
    .flat_map { |field| ["#{field} asc", "#{field} desc"] }

  # A grouped list is a list of ships rather than of vehicles, so it can only
  # follow the sorts that name the ship, restated in Model's own terms. The
  # vehicle's dates have no counterpart and fall back to the name.
  def self.model_sorts(sorts)
    Array(sorts).filter_map { |sort| sort.delete_prefix("model_") if sort.start_with?("model_") }
      .presence || ["name asc"]
  end
end
