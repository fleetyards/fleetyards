# frozen_string_literal: true

module V1
  module Schemas
    class SearchResult
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          type: {"$ref": "#/components/schemas/SearchResultTypeEnum"},
          item: {
            oneOf: [{
              "$ref": "#/components/schemas/Model"
            }, {
              "$ref": "#/components/schemas/Component"
            }, {
              "$ref": "#/components/schemas/Commodity"
            }, {
              "$ref": "#/components/schemas/Equipment"
            }, {
              "$ref": "#/components/schemas/ModelModule"
            }, {
              "$ref": "#/components/schemas/ModelPaint"
            }, {
              "$ref": "#/components/schemas/Shop"
            }, {
              "$ref": "#/components/schemas/Station"
            }, {
              "$ref": "#/components/schemas/CelestialObject"
            }, {
              "$ref": "#/components/schemas/Starsystem"
            }]
          }
        },
        additionalProperties: false,
        required: %w[id type item]
      })
    end
  end
end
