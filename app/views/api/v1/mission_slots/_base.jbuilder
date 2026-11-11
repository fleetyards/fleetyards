# frozen_string_literal: true

json.id mission_slot.id
json.slottable_type mission_slot.slottable_type
json.slottable_id mission_slot.slottable_id
json.title mission_slot.title
json.description mission_slot.description
json.position mission_slot.position
json.derived mission_slot.derived?
json.position_type mission_slot.position_type

json.candidates do
  json.array! mission_slot.mission_slot_candidates,
    partial: "api/v1/slot_candidates/slot_candidate",
    as: :slot_candidate
end
