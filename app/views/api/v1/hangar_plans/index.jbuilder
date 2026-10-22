# frozen_string_literal: true

json.array! @hangar_plans do |hangar_plan|
  json.id hangar_plan.id
  json.name hangar_plan.name
  json.description hangar_plan.description
  json.based_on_at hangar_plan.based_on_at.utc.iso8601
  json.shared hangar_plan.shared?
  json.slots_count hangar_plan.slots.size
  json.partial! "api/shared/dates", record: hangar_plan
end
