# frozen_string_literal: true

json.id fleet_event_ship.id
json.fleet_event_team_id fleet_event_ship.fleet_event_team_id
json.title fleet_event_ship.title
json.display_title fleet_event_ship.display_title
json.description fleet_event_ship.description
json.position fleet_event_ship.position
json.strict fleet_event_ship.strict?

if fleet_event_ship.model.present?
  json.model do
    json.partial! "api/v1/shared/ship_model", model: fleet_event_ship.model
  end
else
  json.model nil
end

# The models this spot will take when it names several rather than one. Empty for
# the other two kinds of spot, so the client can tell them apart by shape.
json.allowed_models do
  json.array!(fleet_event_ship.allowed_models) do |model|
    json.partial! "api/v1/shared/ship_model", model: model
  end
end

json.filters do
  json.classification fleet_event_ship.classification
  json.focus fleet_event_ship.focus
  json.min_size fleet_event_ship.min_size
  json.max_size fleet_event_ship.max_size
  json.min_crew fleet_event_ship.min_crew
  json.min_cargo fleet_event_ship.min_cargo&.to_f
end

json.slots do
  json.array! fleet_event_ship.fleet_event_slots,
    partial: "api/v1/fleet_event_slots/fleet_event_slot",
    as: :fleet_event_slot,
    locals: {occurrence_date: local_assigns[:occurrence_date]}
end
