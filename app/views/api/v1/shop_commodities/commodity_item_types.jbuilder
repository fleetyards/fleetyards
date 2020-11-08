# frozen_string_literal: true

json.array! @commodity_item_types, partial: 'api/v1/shop_commodities/commodity_item_type', as: :item_type
