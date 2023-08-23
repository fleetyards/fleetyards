# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Hardpoints
        class ModelHardpoint
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              category: {"$ref": "#/components/schemas/ModelHardpointCategoryEnum"},
              categoryLabel: {type: :string},
              component: {"$ref": "#/components/schemas/Component"},
              details: {type: :string},
              group: {"$ref": "#/components/schemas/ModelHardpointGroupEnum"},
              itemSlots: {type: :string},
              key: {type: :string},
              loadoutIdentifier: {type: :string, format: :uuid},
              loadouts: {type: :array, items: {"$ref": "#/components/schemas/ModelHardpointLoadout"}},
              mount: {type: :string},
              name: {type: :string},
              size: {"$ref": "#/components/schemas/ModelHardpointSizeEnum"},
              sizeLabel: {type: :string},
              source: {"$ref": "#/components/schemas/ModelHardpointSourceEnum"},
              subCategory: {"$ref": "#/components/schemas/ModelHardpointSubCategoryEnum"},
              subCategoryLabel: {type: :string},
              type: {"$ref": "#/components/schemas/ModelHardpointTypeEnum"},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id key type group createdAt updatedAt]
          })
        end
      end
    end
  end
end
