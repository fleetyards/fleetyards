# frozen_string_literal: true

json.id fleet_event_admin.id
json.fleet_event_id fleet_event_admin.fleet_event_id
json.role fleet_event_admin.role
json.created_at fleet_event_admin.created_at
json.user do
  json.id fleet_event_admin.user.id
  json.username fleet_event_admin.user.username
end
if fleet_event_admin.granted_by.present?
  json.granted_by do
    json.id fleet_event_admin.granted_by.id
    json.username fleet_event_admin.granted_by.username
  end
else
  json.granted_by nil
end
