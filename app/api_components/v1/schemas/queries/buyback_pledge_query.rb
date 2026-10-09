# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class BuybackPledgeQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kindEq: ::V1::Schemas::Enums::BuybackPledgeKindEnum,
            nameCont: {type: :string},
            priceGteq: {type: :number},
            priceLteq: {type: :number},
            priceIn: {type: :array, items: {type: :string}},
            insuranceIn: {type: :array, items: {type: :string}, description: "`lifetime`, `none` or a number of months"},
            upgradeFromModelSlugEq: {type: :string},
            upgradeToModelSlugEq: {type: :string},
            s: ::V1::Schemas::Enums::BuybackPledgeSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::BuybackPledgeSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
