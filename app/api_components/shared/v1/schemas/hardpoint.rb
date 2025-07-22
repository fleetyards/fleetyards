# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Hardpoint
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            group: {"$ref": "#/components/schemas/HardpointGroupEnum"},
            groupKey: {type: :string},
            matrixKey: {type: :string},
            category: {"$ref": "#/components/schemas/HardpointCategoryEnum"},
            name: {type: :string},
            minSize: {type: :integer},
            maxSize: {type: :integer},
            source: {"$ref": "#/components/schemas/HardpointSourceEnum"},
            types: {type: :array, items: {type: :string}},
            details: {type: :string},
            component: {"$ref": "#/components/schemas/Component"},
            hardpoints: {type: :array, items: {"$ref": "#/components/schemas/Hardpoint"}},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name createdAt updatedAt]
        })
      end
    end
  end
end
