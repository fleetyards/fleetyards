# frozen_string_literal: true

# A ship of the live hangar the plan melts for store credit. What the user paid
# is unknown, so the credit is estimated from today's store price unless they
# enter it.
class HangarPlanMelt < ApplicationRecord
  belongs_to :hangar_plan, touch: true
  belongs_to :vehicle, optional: true
  belongs_to :model

  validates :vehicle_id, uniqueness: {scope: :hangar_plan_id}
  validates :value_override, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :vehicle_available, on: :create

  before_validation -> { self.model_id ||= vehicle&.model_id }
  before_create -> { self.value_snapshot ||= list_value }

  def list_value
    model&.pledge_price
  end

  def value
    value_override || list_value
  end

  def snapshot_value
    value_override || value_snapshot
  end

  def estimated?
    value_override.nil?
  end

  def vehicle_missing?
    vehicle.nil? || hangar_plan.live_vehicle_ids.exclude?(vehicle.id)
  end

  def vehicle_changed?
    !vehicle_missing? && vehicle.model_id != model_id
  end

  private def vehicle_available
    return if hangar_plan.blank?

    if vehicle.blank? || hangar_plan.live_vehicles.where(id: vehicle.id).none?
      errors.add(:vehicle_id, :invalid)
    elsif hangar_plan.acquisitions.where(source_vehicle_id: vehicle_id).exists?
      errors.add(:vehicle_id, :taken)
    end
  end
end
