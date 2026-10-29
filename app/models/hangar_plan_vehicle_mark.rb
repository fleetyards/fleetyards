# frozen_string_literal: true

# What the plan says about a hangar ship it does not route or melt: "pending"
# waits for a decision, "change" says it will not stay as it is, and "keep"
# keeps it as it is, which needs no slot. A route or melt for the ship
# overrides the mark; the mark stays behind, so removing that route or melt
# brings it back.
class HangarPlanVehicleMark < ApplicationRecord
  MARKS = %w[pending change keep].freeze

  belongs_to :hangar_plan, touch: true
  belongs_to :vehicle, optional: true

  validates :mark, inclusion: {in: MARKS}
  validates :vehicle_id, uniqueness: {scope: :hangar_plan_id}
  validate :vehicle_available, on: :create

  private def vehicle_available
    return if hangar_plan.blank?
    return if vehicle.present? && hangar_plan.live_vehicles.where(id: vehicle.id).exists?

    errors.add(:vehicle_id, :invalid)
  end
end
