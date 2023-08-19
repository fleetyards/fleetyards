# frozen_string_literal: true

json.array! @shops, partial: "api/v1/shops/shop", as: :shop
