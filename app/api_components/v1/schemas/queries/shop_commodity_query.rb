# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ShopCommodityQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            priceGteq: {type: :number},
            priceLteq: {type: :number},
            name: {type: :array, items: {type: :string}},
            manufacturerSlug: {type: :array, items: {type: :string}},
            category: {type: :array, items: {type: :string}},
            subCategory: {type: :array, items: {type: :string}}
          },
          additionalProperties: false
        })
      end
    end
  end
end
