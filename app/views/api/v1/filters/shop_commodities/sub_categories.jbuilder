# frozen_string_literal: true

json.array! @filters, partial: "api/v1/filters/shop_commodities/sub_category", as: :filter
