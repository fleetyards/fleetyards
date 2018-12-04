# frozen_string_literal: true

json.array! @shop_commodities, partial: 'api/v1/shop_commodities/minimal', as: :shop_commodity
