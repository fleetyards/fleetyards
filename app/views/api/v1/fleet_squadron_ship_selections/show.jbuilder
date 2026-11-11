# frozen_string_literal: true

json.ships_filter @row.ships_filter
json.hangar_group_id @row.hangar_group_id
json.vehicle_ids @row.fleet_squadron_membership_vehicles.map(&:vehicle_id)
