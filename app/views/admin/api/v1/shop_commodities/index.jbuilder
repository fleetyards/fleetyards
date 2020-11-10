# frozen_string_literal: true

json.array! @shop_commodities, partial: 'admin/api/v1/shop_commodities/complete', as: :shop_commodity
