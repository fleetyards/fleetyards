# frozen_string_literal: true

json.id fleet_event_slot.id
json.slottable_type fleet_event_slot.slottable_type
json.slottable_id fleet_event_slot.slottable_id
json.title fleet_event_slot.title
json.description fleet_event_slot.description
json.position fleet_event_slot.position
json.derived fleet_event_slot.derived?
json.position_type fleet_event_slot.position_type
json.signup_approval fleet_event_slot.signup_approval
json.effective_signup_approval fleet_event_slot.signup_approval.presence ||
  fleet_event_slot.fleet_event&.signup_approval ||
  "direct"

json.signups do
  json.array! fleet_event_slot.active_signups,
    partial: "api/v1/fleet_event_signups/fleet_event_signup",
    as: :fleet_event_signup
end
