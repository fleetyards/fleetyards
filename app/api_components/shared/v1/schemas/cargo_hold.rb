# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHold
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            dimensions: {"$ref": "#/components/schemas/Dimension"},
            minContainer: {"$ref": "#/components/schemas/Dimension"},
            maxContainer: {"$ref": "#/components/schemas/Dimension"}
          },
          additionalProperties: false,
          required: %w[dimensions minContainer]
        })
      end
    end
  end
end
