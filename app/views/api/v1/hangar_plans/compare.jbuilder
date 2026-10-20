# frozen_string_literal: true

json.other_plan_id @other_plan.id
json.other_plan_name @other_plan.name
json.models @models, partial: "api/v1/hangar_plans/model_diff", as: :diff
json.totals do
  json.left { json.partial! "api/v1/hangar_plans/totals", summary: @summaries.first }
  json.right { json.partial! "api/v1/hangar_plans/totals", summary: @summaries.last }
end
json.metrics do
  json.left { json.partial! "api/v1/hangar_plans/metrics", metrics: HangarPlans::Metrics.for(@plan_models.first) }
  json.right { json.partial! "api/v1/hangar_plans/metrics", metrics: HangarPlans::Metrics.for(@plan_models.last) }
end
