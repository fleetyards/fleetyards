# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ComponentQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              nameCont: {type: :string},
              itemTypeCont: {type: :string},
              componentClassCont: {type: :string},
              storeImageBlank: {type: :boolean},
              idIn: {type: :array, items: {type: :string, format: :uuid}},
              nameIn: {type: :array, items: {type: :string}},
              itemTypeIn: {type: :array, items: {type: :string}},
              componentClassIn: {type: :array, items: {type: :string}},
              manufacturerIdIn: {type: :array, items: {type: :string, format: :uuid}},

              # Compared against the same cheapest-of-that-direction figure the
              # payload exposes as `buyPrice`/`sellPrice`.
              buyPriceGteq: {type: :number},
              buyPriceLteq: {type: :number},
              sellPriceGteq: {type: :number},
              sellPriceLteq: {type: :number},

              sorts: {anyOf: [{
                type: :array, items: ::Admin::V1::Schemas::Sorts::ComponentSortEnum
              }, ::Admin::V1::Schemas::Sorts::ComponentSortEnum]}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
