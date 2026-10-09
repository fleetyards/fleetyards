# frozen_string_literal: true

json.inactive_members do
  json.count @inactive_count
  json.sample @inactive_sample, partial: "api/v1/fleet_health/member", as: :membership
end

if @unverified_sample
  json.unverified_members do
    json.count @unverified_count
    json.sample @unverified_sample, partial: "api/v1/fleet_health/member", as: :membership
  end
else
  json.unverified_members nil
end

if @empty_roles
  json.empty_roles @empty_roles do |role|
    json.id role.id
    json.name role.name
  end
else
  json.empty_roles nil
end
