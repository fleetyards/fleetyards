# frozen_string_literal: true

json.array! @admins,
  partial: "api/v1/fleet_event_admins/fleet_event_admin",
  as: :fleet_event_admin
