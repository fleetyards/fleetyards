# frozen_string_literal: true

json.id fleet_event_signup.id
json.fleet_event_id fleet_event_signup.fleet_event_id
json.fleet_event_slot_id fleet_event_signup.fleet_event_slot_id
json.status fleet_event_signup.status
json.notes fleet_event_signup.notes
json.confirmed_at fleet_event_signup.confirmed_at
json.withdrawn_at fleet_event_signup.withdrawn_at

if fleet_event_signup.user.present?
  json.user do
    json.id fleet_event_signup.user.id
    json.username fleet_event_signup.user.username
  end
else
  json.user nil
end

if fleet_event_signup.vehicle.present?
  json.vehicle do
    json.id fleet_event_signup.vehicle.id
    json.name fleet_event_signup.vehicle.name
    if fleet_event_signup.vehicle.model.present?
      json.model do
        json.id fleet_event_signup.vehicle.model.id
        json.name fleet_event_signup.vehicle.model.name
        json.slug fleet_event_signup.vehicle.model.slug
      end
    else
      json.model nil
    end
  end
else
  json.vehicle nil
end
