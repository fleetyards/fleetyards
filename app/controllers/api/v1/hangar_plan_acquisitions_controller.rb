# frozen_string_literal: true

module Api
  module V1
    class HangarPlanAcquisitionsController < ::Api::BaseController
      include HangarPlannerFeatureConcern
      include HangarPlanScopedConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" }, unless: :user_signed_in?
      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan
      before_action :set_acquisition, only: %i[update destroy]

      def create
        candidate = @hangar_plan.candidates.find(params[:candidate_id])
        @acquisition = @hangar_plan.acquisitions.new(acquisition_params.merge(candidate:))

        if save_with_steps(@acquisition, params.fetch(:steps, []))
          render_hangar_plan(status: :created)
        else
          render json: ValidationError.new("hangar_plan_acquisitions.create", errors: @acquisition.errors), status: :bad_request
        end
      end

      def update
        @acquisition.assign_attributes(
          params.permit(:start_kind, :source_vehicle_id, :buyback_pledge_id, :start_model_id, :price_override, :uses_buyback_token)
        )

        steps = params.key?(:steps) ? params.fetch(:steps, []) : nil
        if save_with_steps(@acquisition, steps)
          render_hangar_plan
        else
          render json: ValidationError.new("hangar_plan_acquisitions.update", errors: @acquisition.errors), status: :bad_request
        end
      end

      def destroy
        @acquisition.destroy!

        render_hangar_plan
      end

      private def set_acquisition
        @acquisition = @hangar_plan.acquisitions.find(params[:id])
      end

      private def acquisition_params
        params.permit(:start_kind, :source_vehicle_id, :buyback_pledge_id, :start_model_id, :price_override, :uses_buyback_token)
      end

      # The old chain goes before the new one is checked: a step that spends an
      # upgrade the chain already spent would otherwise count it twice.
      private def save_with_steps(acquisition, steps)
        saved = false

        HangarPlanAcquisition.transaction do
          if steps
            acquisition.upgrade_steps.destroy_all if acquisition.persisted?
            build_steps(acquisition, steps)
          end

          saved = acquisition.save
          raise ActiveRecord::Rollback unless saved
        end

        saved
      end

      private def build_steps(acquisition, steps)
        previous_model_id = acquisition.start_model_id || acquisition.source_vehicle&.model_id

        Array(steps).each_with_index do |step, index|
          step = step.permit(:source_kind, :from_model_id, :to_model_id, :hangar_pledge_item_id, :buyback_pledge_id, :price_override,
            :uses_buyback_token)
          built = acquisition.upgrade_steps.build(step.merge(position: index, hangar_plan: @hangar_plan))
          built.from_model_id ||= previous_model_id
          previous_model_id = built.to_model_id
        end
      end
    end
  end
end
