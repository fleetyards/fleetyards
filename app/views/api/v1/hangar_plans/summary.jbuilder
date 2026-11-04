# frozen_string_literal: true

json.totals do
  json.partial! "api/v1/hangar_plans/totals", summary: @summary
end

json.slots @summary.slot_costs do |cost|
  json.slot_id cost.slot_id
  json.state cost.state
  json.min_cost cost.min_cost.to_f
  json.max_cost cost.max_cost.to_f
  # Its low end comes from the owner's free ships, which a shared plan keeps private.
  json.store_cost_min((@public_view ? cost.store_cost : cost.store_cost_min)&.to_f)
  json.store_cost cost.store_cost&.to_f
  json.unresolved_count cost.unresolved_count
  json.complete cost.complete
end

json.issues @summary.issues do |issue|
  json.kind issue.kind
  json.name issue.name
  json.slot_id issue.slot_id
end
