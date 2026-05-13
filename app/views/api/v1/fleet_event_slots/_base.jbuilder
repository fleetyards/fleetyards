# frozen_string_literal: true

json.id fleet_event_slot.id
json.slottable_type fleet_event_slot.slottable_type
json.slottable_id fleet_event_slot.slottable_id
json.title fleet_event_slot.title
json.description fleet_event_slot.description
json.position fleet_event_slot.position
json.derived fleet_event_slot.derived?
json.position_type fleet_event_slot.position_type
json.model_position_id fleet_event_slot.model_position_id
json.signup_approval fleet_event_slot.signup_approval
json.effective_signup_approval fleet_event_slot.signup_approval.presence ||
  fleet_event_slot.fleet_event&.signup_approval ||
  "direct"

occurrence_date = local_assigns[:occurrence_date]
signup_scope = fleet_event_slot.active_signups
signup_scope = signup_scope.where(occurrence_date: occurrence_date) if occurrence_date

json.signups do
  json.array! signup_scope,
    partial: "api/v1/fleet_event_signups/fleet_event_signup",
    as: :fleet_event_signup
end
