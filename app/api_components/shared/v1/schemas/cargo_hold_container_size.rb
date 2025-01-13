# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHoldContainerSize
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            size: {type: :integer},
            dimensions: {"$ref": "#/components/schemas/CargoHoldDimension"}
          },
          additionalProperties: false,
          required: %w[size dimensions]
        })
      end
    end
  end
end
