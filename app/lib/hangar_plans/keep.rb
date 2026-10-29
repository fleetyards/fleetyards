# frozen_string_literal: true

module HangarPlans
  # Keeps hangar ships as they are. A ship the plan does not change needs no
  # slot, so keeping it only marks it, whatever it was marked before.
  class Keep
    attr_reader :plan

    def initialize(plan)
      @plan = plan
    end

    def run(vehicles)
      now = Time.current
      rows = vehicles.map do |vehicle|
        {hangar_plan_id: plan.id, vehicle_id: vehicle.id, mark: "keep", created_at: now, updated_at: now}
      end
      return if rows.empty?

      HangarPlanVehicleMark.upsert_all(rows, unique_by: :index_hangar_plan_vehicle_marks_on_plan_and_vehicle,
        update_only: %i[mark])
      plan.touch
    end
  end
end
