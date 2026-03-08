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
            },
            offset: {
              type: :object,
              nullable: true,
              properties: {
                x: {type: :number},
                y: {type: :number},
                z: {type: :number}
              },
              additionalProperties: false,
              required: %w[x y z]
            },
            rotation: {type: :integer, nullable: true}
          },
          additionalProperties: false,
          required: %w[dimensions capacity maxContainerSize limits]
        })
      end
    end
  end
end
