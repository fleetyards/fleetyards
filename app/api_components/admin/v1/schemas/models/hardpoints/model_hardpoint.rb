# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Hardpoints
          class ModelHardpoint
            include Rswag::SchemaComponents::Component

            schema({
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                name: {type: :string},
                type: {"$ref": "#/components/schemas/ModelHardpointTypeEnum"},
                group: {"$ref": "#/components/schemas/ModelHardpointGroupEnum"},
                source: {"$ref": "#/components/schemas/HardpointSourceEnum"},
                category: {"$ref": "#/components/schemas/ModelHardpointCategoryEnum"},
                categoryLabel: {type: :string},
                subCategory: {"$ref": "#/components/schemas/ModelHardpointSubCategoryEnum"},
                subCategoryLabel: {type: :string},
                size: {"$ref": "#/components/schemas/ModelHardpointSizeEnum"},
                sizeLabel: {type: :string},
                key: {type: :string},
                loadoutIdentifier: {type: :string, format: :uuid},
                details: {type: :string},
                mount: {type: :string},
                itemSlots: {type: :integer},
                modelId: {type: :string, format: :uuid},
                component: {"$ref": "#/components/schemas/Component"},
                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"}
              },
              additionalProperties: false,
              required: %w[id key type group modelId createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
