# frozen_string_literal: true

json.items do
  json.array! @fleet_subscriptions, partial: "admin/api/v1/fleet_subscriptions/fleet_subscription", as: :fleet_subscription
end
json.partial! "api/shared/meta", result: @fleet_subscriptions
