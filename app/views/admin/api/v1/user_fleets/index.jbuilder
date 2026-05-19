# frozen_string_literal: true

json.items do
  json.array! @memberships, partial: "admin/api/v1/user_fleets/user_fleet", as: :membership
end
json.partial! "api/shared/meta", result: @memberships
