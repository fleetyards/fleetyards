# frozen_string_literal: true

module Api
  module V1
    class HangarPlanMeltsController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan
      before_action :set_melt, only: %i[update destroy]

      def create
        @melt = @hangar_plan.melts.new(vehicle: Vehicle.find_by(id: params[:vehicle_id]), value_override: params[:value_override])

        if @melt.save
          render_hangar_plan(status: :created)
        else
          render json: ValidationError.new("hangar_plan_melts.create", errors: @melt.errors), status: :bad_request
        end
      end

      def update
        if @melt.update(params.permit(:value_override))
          render_hangar_plan
        else
          render json: ValidationError.new("hangar_plan_melts.update", errors: @melt.errors), status: :bad_request
        end
      end

      def destroy
        @melt.destroy!

        render_hangar_plan
      end

      private def set_melt
        @melt = @hangar_plan.melts.find(params[:id])
      end
    end
  end
end
