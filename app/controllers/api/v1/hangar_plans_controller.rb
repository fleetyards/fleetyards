# frozen_string_literal: true

module Api
  module V1
    class HangarPlansController < ::Api::BaseController
      include HangarPlannerFeatureConcern

      READ_ACTIONS = %i[index show summary comparison compare drift resources].freeze

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: READ_ACTIONS
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: READ_ACTIONS

      before_action :check_hangar_planner_feature
      before_action :set_hangar_plan, except: %i[index create]

      def index
        authorize! with: HangarPlanPolicy

        @hangar_plans = authorized_scope(HangarPlan.all, with: HangarPlanPolicy)
          .includes(:slots)
          .order(updated_at: :desc)
      end

      def show
      end

      def create
        @hangar_plan = current_resource_owner.hangar_plans.new(hangar_plan_params)

        authorize! @hangar_plan, with: HangarPlanPolicy

        source = params[:source].presence || "empty"
        source_plan = current_resource_owner.hangar_plans.find(params[:source_plan_id]) if source == "plan"

        HangarPlans::Builder.new(@hangar_plan, source:, source_plan:).run

        render :show, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("hangar_plans.create", errors: e.record.errors), status: :bad_request
      end

      def update
        if @hangar_plan.update(hangar_plan_params)
          render :show
        else
          render json: ValidationError.new("hangar_plans.update", errors: @hangar_plan.errors), status: :bad_request
        end
      end

      def destroy
        @hangar_plan.destroy!

        render json: {success: true}
      end

      def summary
        @summary = HangarPlans::Summary.new(@hangar_plan)
      end

      def comparison
        @comparison = HangarPlans::Comparison.new(@hangar_plan)
      end

      def compare
        @other_plan = authorized_scope(HangarPlan.all, with: HangarPlanPolicy).find(params[:other_id])

        @models = HangarPlans::Comparison.diff(
          HangarPlans::Metrics.plan_models(@hangar_plan),
          HangarPlans::Metrics.plan_models(@other_plan)
        )
        @summaries = [HangarPlans::Summary.new(@hangar_plan), HangarPlans::Summary.new(@other_plan)]
      end

      def drift
        @drift = HangarPlans::Drift.new(@hangar_plan)
      end

      def rebase
        HangarPlans::Drift.new(@hangar_plan).rebase!
        @hangar_plan.reload

        render :show
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("hangar_plans.rebase", errors: e.record.errors), status: :bad_request
      end

      def add_to_wishlist
        @result = HangarPlans::WishlistApply.new(@hangar_plan).run
      end

      def share
        @hangar_plan.share!

        render :show
      end

      def unshare
        @hangar_plan.unshare!

        render :show
      end

      def resources
        @resources = HangarPlans::Resources.new(@hangar_plan)
      end

      private def set_hangar_plan
        @hangar_plan = authorized_scope(HangarPlan.all, with: HangarPlanPolicy).find(params[:id])

        authorize! @hangar_plan, to: :show?, with: HangarPlanPolicy
      end

      private def hangar_plan_params
        params.permit(:name, :description, :starting_credit)
      end
    end
  end
end
