# frozen_string_literal: true

json.array! @trade_routes, partial: "api/v1/trade_routes/trade_route", as: :trade_route
