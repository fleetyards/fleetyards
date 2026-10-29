# frozen_string_literal: true

# What the plan says about a hangar ship it does not route or melt: "pending"
# waits for a decision, "change" says it will not stay as it is, and "keep"
# keeps it as it is, which needs no slot. A route or melt for the ship
# overrides the mark; the mark stays behind, so removing that route or melt
# brings it back.
class HangarPlanVehicleMark < ApplicationRecord
  MARKS = %w[pending change keep].freeze
  UNIQUE_INDEX = :index_hangar_plan_vehicle_marks_on_plan_and_vehicle

  belongs_to :hangar_plan, touch: true
  belongs_to :vehicle, optional: true
  belongs_to :model

  validates :mark, inclusion: {in: MARKS}
  validates :vehicle_id, uniqueness: {scope: :hangar_plan_id}
  validate :vehicle_available, on: :create
  validate :not_melted, if: -> { mark == "keep" }

  before_validation -> { self.model_id ||= vehicle&.model_id }

  # Marks many ships at once, without validations: the callers have checked
  # them. A ship marked already keeps its mark unless `overwrite` says so.
  def self.write(plan, vehicles, mark, overwrite: false)
    now = Time.current
    rows = vehicles.map do |vehicle|
      {hangar_plan_id: plan.id, vehicle_id: vehicle.id, model_id: vehicle.model_id, mark:, created_at: now, updated_at: now}
    end
    return if rows.empty?

    if overwrite
      upsert_all(rows, unique_by: UNIQUE_INDEX, update_only: %i[mark])
    else
      insert_all(rows, unique_by: UNIQUE_INDEX)
    end
    plan.touch
  end

  private def vehicle_available
    return if hangar_plan.blank?
    return if vehicle.present? && hangar_plan.live_vehicles.where(id: vehicle.id).exists?

    errors.add(:vehicle_id, :invalid)
  end

  private def not_melted
    return if hangar_plan.blank?

    errors.add(:vehicle_id, :pledge_melted) if hangar_plan.melted_vehicle_ids.include?(vehicle_id)
  end
end
