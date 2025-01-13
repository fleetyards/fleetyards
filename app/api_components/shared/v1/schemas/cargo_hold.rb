# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHold
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            dimensions: {"$ref": "#/components/schemas/CargoHoldDimension"},
            capacity: {type: :integer},
            maxContainerSize: {"$ref": "#/components/schemas/CargoHoldContainerSize"},
            limits: {
              type: :object,
              properties: {
                min: {"$ref": "#/components/schemas/CargoHoldLimit"},
                max: {"$ref": "#/components/schemas/CargoHoldLimit"}
              },
              additionalProperties: false,
              required: %w[min]
            }
          },
          additionalProperties: false,
          required: %w[dimensions capacity maxContainerSize limits]
        })
      end
    end
  end
end
