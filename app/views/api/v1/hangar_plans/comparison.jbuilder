# frozen_string_literal: true

json.vehicles @comparison.vehicles do |entry|
  json.vehicle_id entry.vehicle.id
  json.name entry.vehicle.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: entry.vehicle.model
  end
  json.status entry.status
  if entry.target_model
    json.target_model do
      json.partial! "api/v1/hangar_plans/model", model: entry.target_model
    end
  end
end

json.models @comparison.models, partial: "api/v1/hangar_plans/model_diff", as: :diff

json.gaps @comparison.gaps do |gap|
  json.slot_id gap.slot.id
  json.label gap.slot.label
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: gap.model
  end
  json.count gap.count
end

metrics = @comparison.metrics
json.metrics do
  json.live { json.partial! "api/v1/hangar_plans/metrics", metrics: metrics[:live] }
  json.plan { json.partial! "api/v1/hangar_plans/metrics", metrics: metrics[:plan] }
end
