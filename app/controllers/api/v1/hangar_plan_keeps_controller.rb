# frozen_string_literal: true

module Api
  module V1
    class HangarPlanKeepsController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan

      def create
        ids = Array(params[:vehicle_ids]).uniq
        vehicles = @hangar_plan.live_vehicles.where(id: ids).to_a
        mark = @hangar_plan.vehicle_marks.new

        if ids.empty? || vehicles.size != ids.size
          mark.errors.add(:vehicle_id, :invalid)
        elsif @hangar_plan.used_vehicle_ids.intersect?(ids)
          mark.errors.add(:vehicle_id, :taken)
        end

        if mark.errors.any?
          render json: ValidationError.new("hangar_plan_keeps.create", errors: mark.errors), status: :bad_request
        else
          HangarPlans::Keep.new(@hangar_plan).run(vehicles)
          render_hangar_plan(status: :created)
        end
      end
    end
  end
end
