# frozen_string_literal: true

json.total_count check[:total_count]
json.items check[:items], partial: "api/v1/fleet_member_health/member", as: :membership, leader_role_ids:, reminders: check[:reminders] || {}
