# frozen_string_literal: true

json.array! @shop_commodities, partial: "api/v1/shop_commodities/shop_commodity", locals: {extended: true}, as: :shop_commodity
