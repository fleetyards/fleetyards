# frozen_string_literal: true

module Admin
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
                name: {type: :string},
                type: ::Shared::V1::Schemas::Enums::ModelHardpointTypeEnum,
                group: ::Shared::V1::Schemas::Enums::ModelHardpointGroupEnum,
                source: ::Shared::V1::Schemas::Enums::HardpointSourceEnum,
                category: ::Shared::V1::Schemas::Enums::ModelHardpointCategoryEnum,
                categoryLabel: {type: :string},
                subCategory: ::Shared::V1::Schemas::Enums::ModelHardpointSubCategoryEnum,
                subCategoryLabel: {type: :string},
                size: ::Shared::V1::Schemas::Enums::ModelHardpointSizeEnum,
                sizeLabel: {type: :string},
                key: {type: :string},
                loadoutIdentifier: {type: :string, format: :uuid},
                details: {type: :string},
                mount: {type: :string},
                itemSlots: {type: :integer},
                modelId: {type: :string, format: :uuid},
                component: {"$ref": "#/components/schemas/Component"},
                loadouts: {type: :array, items: {"$ref": "#/components/schemas/ModelHardpointLoadout"}},
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
