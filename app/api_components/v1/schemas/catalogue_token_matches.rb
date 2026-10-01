# frozen_string_literal: true

module V1
  module Schemas
    class CatalogueTokenMatches
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        required: %i[items],
        properties: {
          items: {type: :array, items: {"$ref": "#/components/schemas/CatalogueTokenMatch"}}
        }
      })
    end
  end
end
