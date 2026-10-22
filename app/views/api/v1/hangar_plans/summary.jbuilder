# frozen_string_literal: true

json.totals do
  json.partial! "api/v1/hangar_plans/totals", summary: @summary
end

json.slots @summary.slot_costs do |cost|
  json.slot_id cost.slot_id
  json.state cost.state
  json.min_cost cost.min_cost.to_f
  json.max_cost cost.max_cost.to_f
  json.unresolved_count cost.unresolved_count
  json.complete cost.complete
end

json.issues @summary.issues do |issue|
  json.kind issue.kind
  json.name issue.name
  json.slot_id issue.slot_id
end
