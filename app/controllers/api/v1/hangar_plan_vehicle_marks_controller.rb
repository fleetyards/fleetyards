# frozen_string_literal: true

module Api
  module V1
    class HangarPlanVehicleMarksController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan
      before_action :set_mark, only: %i[update destroy]

      def create
        @mark = @hangar_plan.vehicle_marks.new(vehicle: Vehicle.find_by(id: params[:vehicle_id]), mark: params[:mark])

        if @mark.save
          render_hangar_plan(status: :created)
        else
          render json: ValidationError.new("hangar_plan_vehicle_marks.create", errors: @mark.errors), status: :bad_request
        end
      end

      def update
        if @mark.update(params.permit(:mark))
          render_hangar_plan
        else
          render json: ValidationError.new("hangar_plan_vehicle_marks.update", errors: @mark.errors), status: :bad_request
        end
      end

      def destroy
        @mark.destroy!

        render_hangar_plan
      end

      private def set_mark
        @mark = @hangar_plan.vehicle_marks.find(params[:id])
      end
    end
  end
end
