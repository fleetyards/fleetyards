# frozen_string_literal: true

json.items do
  json.array! @trade_routes, partial: "api/v1/trade_routes/base", as: :trade_route
end
json.partial! "api/shared/meta", result: @trade_routes
