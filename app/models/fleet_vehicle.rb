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
  ALLOWED_SORTING_PARAMS = (MODEL_SORT_FIELDS + %w[createdAt updatedAt vehiclesCount])
    .flat_map { |field| ["#{field} asc", "#{field} desc"] }

  # A grouped list is a list of ships rather than of vehicles, so it can only
  # follow the sorts that name the ship, restated in Model's own terms. The
  # vehicle's dates have no counterpart and fall back to the name.
  def self.model_sorts(sorts)
    Array(sorts).filter_map { |sort| sort.delete_prefix("model_") if sort.start_with?("model_") }
      .presence || ["name asc"]
  end

  # How many of a ship the fleet holds only means something once the list is
  # grouped by ship, so this is the one sort a grouped list follows that is not
  # the ship's own. Returns the direction, or nil when it was not asked for.
  def self.count_sort_direction(sorts)
    Array(sorts).find { |sort| sort.start_with?("vehicles_count ") }&.split&.last
  end

  # The sorts a list of vehicles can follow. Each row is one vehicle, so the
  # count sort falls back to the default like any other it cannot answer.
  def self.vehicle_sorts(sorts)
    Array(sorts).reject { |sort| sort.start_with?("vehicles_count ") }
      .presence || DEFAULT_SORTING_PARAMS
  end
end
