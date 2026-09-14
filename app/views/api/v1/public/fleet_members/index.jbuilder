# frozen_string_literal: true

json.items do
  json.array! @members, partial: "api/v1/public/fleet_members/base", as: :member
end
json.partial! "api/shared/meta", result: @members
