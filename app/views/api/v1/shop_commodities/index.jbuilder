# frozen_string_literal: true

json.array! @shop_commodities, partial: "api/v1/shop_commodities/shop_commodity", as: :shop_commodity
