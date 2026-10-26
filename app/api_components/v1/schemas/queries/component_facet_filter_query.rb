# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ComponentFacetFilterQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            categoryIn: {type: :array, items: {type: :string}}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
