# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ManufacturerQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            withModels: {type: :boolean},
            nameEq: {type: :string},
            nameCont: {type: :string},
            nameIn: {type: :array, items: {type: :string}},
            slugEq: {type: :string},
            slugCont: {type: :string},
            slugIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
