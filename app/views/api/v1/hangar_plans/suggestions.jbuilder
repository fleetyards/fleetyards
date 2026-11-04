# frozen_string_literal: true

json.redundancies @suggestions.redundancies do |redundancy|
  json.kind redundancy.kind
  if redundancy.model
    json.model do
      json.partial! "api/v1/hangar_plans/model", model: redundancy.model
    end
  end
  json.classification_label redundancy.classification&.humanize
  json.size_label redundancy.size&.humanize
  json.focus_label(redundancy.focus && Model.focus_label(redundancy.focus))
  json.entries redundancy.entries do |entry|
    json.model do
      json.partial! "api/v1/hangar_plans/model", model: entry.model
    end
    json.slot_id entry.slot&.id
    json.slot_label entry.slot&.label
    json.vehicle_id entry.vehicle&.id
    json.vehicle_name entry.vehicle&.name
    status = @suggestions.status_of(entry.vehicle)
    json.vehicle_status status if status
  end
end
