# frozen_string_literal: true

json.items do
  json.array! @members, partial: "api/v1/fleet_members/fleet_member", as: :member
end
json.partial! "api/shared/meta", result: @members
