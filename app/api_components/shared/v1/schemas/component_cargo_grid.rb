# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentCargoGrid
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            dimensions: {"$ref": "#/components/schemas/ComponentCargoGridDimensions"},
            minContainer: {"$ref": "#/components/schemas/ComponentCargoGridDimensions"},
            maxContainer: {"$ref": "#/components/schemas/ComponentCargoGridDimensions"}
          },
          additionalProperties: false,
          required: %w[dimensions minContainer]
        })
      end
    end
  end
end
