# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Hardpoint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            group: ::Shared::V1::Schemas::Enums::HardpointGroupEnum,
            groupKey: {type: :string},
            matrixKey: {type: :string},
            category: ::Shared::V1::Schemas::Enums::HardpointCategoryEnum,
            name: {type: :string},
            minSize: {type: :integer},
            maxSize: {type: :integer},
            source: ::Shared::V1::Schemas::Enums::HardpointSourceEnum,
            types: {type: :array, items: {type: :string}},
            details: {type: :string},
            component: {"$ref": "#/components/schemas/Component"},
            hardpoints: {type: :array, items: ::Shared::V1::Schemas::Hardpoint},
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
