# frozen_string_literal: true

json.based_on_at @hangar_plan.based_on_at.utc.iso8601
json.missing_sources @drift.missing_sources, partial: "api/v1/hangar_plans/source_issue", as: :source_issue
json.changed_sources @drift.changed_sources, partial: "api/v1/hangar_plans/source_issue", as: :source_issue
json.new_vehicles @drift.new_vehicles do |vehicle|
  json.vehicle_id vehicle.id
  json.name vehicle.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: vehicle.model
  end
end
json.arrivals @drift.progress.arrivals do |arrival|
  json.acquisition_id arrival.acquisition.id
  json.vehicle_id arrival.vehicle.id
  json.name arrival.vehicle.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: arrival.vehicle.model
  end
end
json.held_upgrades @drift.progress.held_upgrades do |held|
  json.step_id held.step.id
  json.from_model do
    json.partial! "api/v1/hangar_plans/model", model: held.step.origin_model
  end
  json.to_model do
    json.partial! "api/v1/hangar_plans/model", model: held.step.target_model
  end
end
json.previous_total @drift.previous_total.to_f
json.current_total @drift.current_total.to_f
json.drifted @drift.drifted?
