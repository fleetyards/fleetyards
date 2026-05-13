# frozen_string_literal: true

json.partial! "api/v1/fleet_event_slots/base",
  fleet_event_slot: fleet_event_slot,
  occurrence_date: local_assigns[:occurrence_date]
