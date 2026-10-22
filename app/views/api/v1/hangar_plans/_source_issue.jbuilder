# frozen_string_literal: true

json.kind source_issue.kind
json.record_id source_issue.record_id
json.planned_model do
  json.partial! "api/v1/hangar_plans/model", model: source_issue.planned_model
end
if source_issue.current_model
  json.current_model do
    json.partial! "api/v1/hangar_plans/model", model: source_issue.current_model
  end
end
