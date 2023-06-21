# frozen_string_literal: true

module V1
  module Schemas
    class ModelHardpoint
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          category: {"$ref": "#/components/schemas/ModelHardpointCategoryEnum", nullable: true},
          categoryLabel: {type: :string, nullable: true},
          component: {"$ref": "#/components/schemas/Component", nullable: true},
          details: {type: :string, nullable: true},
          group: {"$ref": "#/components/schemas/ModelHardpointGroupEnum"},
          itemSlots: {type: :string, nullable: true},
          key: {type: :string},
          loadoutIdentifier: {type: :string, format: :uuid, nullable: true},
          loadouts: {type: :array, items: {"$ref": "#/components/schemas/ModelHardpointLoadout"}},
          mount: {type: :string, nullable: true},
          name: {type: :string, nullable: true},
          size: {"$ref": "#/components/schemas/ModelHardpointSizeEnum", nullable: true},
          sizeLabel: {type: :string, nullable: true},
          source: {"$ref": "#/components/schemas/ModelHardpointSourceEnum"},
          subCategory: {"$ref": "#/components/schemas/ModelHardpointSubCategoryEnum", nullable: true},
          subCategoryLabel: {type: :string, nullable: true},
          type: {"$ref": "#/components/schemas/ModelHardpointTypeEnum"}
        },
        required: %w[id key type group]
      })
    end
  end
end
