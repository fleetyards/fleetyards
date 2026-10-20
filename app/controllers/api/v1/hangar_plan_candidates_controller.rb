# frozen_string_literal: true

module Api
  module V1
    class HangarPlanCandidatesController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan
      before_action :set_candidate, only: %i[update destroy]

      def create
        slot = @hangar_plan.slots.find(params[:slot_id])
        @candidate = slot.candidates.new(candidate_params)

        if @candidate.save
          render_hangar_plan(status: :created)
        else
          render json: ValidationError.new("hangar_plan_candidates.create", errors: @candidate.errors), status: :bad_request
        end
      end

      def update
        if @candidate.update(candidate_params.except(:model_id))
          render_hangar_plan
        else
          render json: ValidationError.new("hangar_plan_candidates.update", errors: @candidate.errors), status: :bad_request
        end
      end

      def destroy
        @candidate.destroy!

        render_hangar_plan
      end

      private def set_candidate
        @candidate = @hangar_plan.candidates.find(params[:id])
      end

      private def candidate_params
        permitted = params.permit(:model_id, :model_paint_id, model_module_ids: [], model_upgrade_ids: [])
        permitted[:model_module_ids] = [] if params.key?(:model_module_ids) && params[:model_module_ids].nil?
        permitted[:model_upgrade_ids] = [] if params.key?(:model_upgrade_ids) && params[:model_upgrade_ids].nil?
        permitted
      end
    end
  end
end
