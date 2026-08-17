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
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},
            slugIn: {type: :array, items: {type: :string}},
            commodityTypeIn: {type: :array, items: {type: :string}},
            currentVersion: {type: :boolean}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
