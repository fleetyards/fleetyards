# frozen_string_literal: true

# For the controllers editing the parts of one plan. Every change answers with
# the whole plan, so the editor never has to stitch a partial response in.
module HangarPlanScopedConcern
  extend ActiveSupport::Concern

  private def set_hangar_plan
    @hangar_plan = authorized_scope(HangarPlan.all, with: HangarPlanPolicy).find(params[:hangar_plan_id])

    authorize! @hangar_plan, to: :update?, with: HangarPlanPolicy
  end

  private def render_hangar_plan(status: :ok)
    @hangar_plan = HangarPlan.find(@hangar_plan.id)

    render "api/v1/hangar_plans/show", status:
  end
end
