# frozen_string_literal: true

json.array! @prices, partial: 'admin/api/v1/commodity_prices/base', as: :commodity_price
