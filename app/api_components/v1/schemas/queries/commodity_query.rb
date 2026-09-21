# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class CommodityQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            descriptionCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},
            slugIn: {type: :array, items: {type: :string}},
            commodityTypeIn: {type: :array, items: {type: :string}},

            # The cheapest price in each direction, across every terminal. A
            # range rather than a sort alone, so "sells for over 20,000 aUEC"
            # is a question the API answers instead of something a client pages
            # through and sifts itself.
            buyPriceGteq: {type: :number},
            buyPriceLteq: {type: :number},
            sellPriceGteq: {type: :number},
            sellPriceLteq: {type: :number},

            # Whether anything we know of trades it at all. 124 of the 232 have
            # a price; the other 108 are not cheap, they are unlisted, and a
            # range filter cannot express the difference.
            buyPriceNotNull: {type: :boolean},
            sellPriceNotNull: {type: :boolean},

            currentVersion: {type: :boolean},
            s: ::V1::Schemas::Enums::CommoditySortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::CommoditySortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
