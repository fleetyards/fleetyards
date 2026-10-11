# frozen_string_literal: true

json.inactive_days @inactive_days
json.inactive_members do
  json.total_count @inactive_count
  json.items @inactive_members, partial: "api/v1/fleet_members/fleet_member", as: :member
end

json.fleet_rsi_verified @fleet.rsi_verified?
if @unverified_members
  json.unverified_members do
    json.total_count @unverified_count
    json.items @unverified_members, partial: "api/v1/fleet_members/fleet_member", as: :member
  end
else
  json.unverified_members nil
end

if @empty_roles
  json.empty_roles @empty_roles, partial: "api/v1/fleet_roles/base", as: :fleet_role
else
  json.empty_roles nil
end
