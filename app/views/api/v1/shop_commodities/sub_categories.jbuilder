# frozen_string_literal: true

json.array! @filters, partial: 'api/v1/shop_commodities/sub_category', as: :filter
