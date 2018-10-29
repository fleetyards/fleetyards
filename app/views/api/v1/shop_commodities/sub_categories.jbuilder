# frozen_string_literal: true

json.array! @sub_categories, partial: 'api/v1/shop_commodities/sub_category', as: :sub_category
