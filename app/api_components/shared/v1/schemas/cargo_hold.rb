# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHold
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
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
