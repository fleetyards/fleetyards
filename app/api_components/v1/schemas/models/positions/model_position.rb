# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Positions
        class ModelPosition
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              positionType: {"$ref": "#/components/schemas/ModelPositionTypeEnum"},
              source: {"$ref": "#/components/schemas/ModelPositionSourceEnum"},
              position: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name positionType source position createdAt updatedAt]
          })
        end
      end
    end
  end
end
