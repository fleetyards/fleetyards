# frozen_string_literal: true

module Api
  module V1
    module Public
      # A plan its owner shared by link, read-only. The token is the only key:
      # a plan that is not shared, or shared again under a new token, is not
      # found here.
      class HangarPlansController < ::Api::PublicBaseController
        before_action :set_hangar_plan

        def show
          render "api/v1/hangar_plans/show"
        end

        def summary
          @summary = HangarPlans::Summary.new(@hangar_plan)

          render "api/v1/hangar_plans/summary"
        end

        private def set_hangar_plan
          token = params[:token].to_s
          raise ActiveRecord::RecordNotFound if token.blank?

          @hangar_plan = HangarPlan.find_by!(share_token: token)
          @public_view = true

          authorize! @hangar_plan, to: :shared?, with: HangarPlanPolicy

          raise ActiveRecord::RecordNotFound unless Flipper.enabled?(:hangar_planner, @hangar_plan.user)
        end
      end
    end
  end
end
