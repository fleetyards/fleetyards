# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Hardpoints
        class ModelHardpoint
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              category: ::Shared::V1::Schemas::Enums::ModelHardpointCategoryEnum,
              categoryLabel: {type: :string},
              component: {"$ref": "#/components/schemas/Component"},
              details: {type: :string},
              group: ::Shared::V1::Schemas::Enums::ModelHardpointGroupEnum,
              itemSlots: {type: :integer},
              key: {type: :string},
              loadoutIdentifier: {type: :string, format: :uuid},
              loadouts: {type: :array, items: {"$ref": "#/components/schemas/ModelHardpointLoadout"}},
              mount: {type: :string},
              name: {type: :string},
              size: ::Shared::V1::Schemas::Enums::ModelHardpointSizeEnum,
              sizeLabel: {type: :string},
              source: ::Shared::V1::Schemas::Enums::HardpointSourceEnum,
              subCategory: ::Shared::V1::Schemas::Enums::ModelHardpointSubCategoryEnum,
              subCategoryLabel: {type: :string},
              type: ::Shared::V1::Schemas::Enums::ModelHardpointTypeEnum,
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
