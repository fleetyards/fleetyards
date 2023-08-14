# frozen_string_literal: true

module V1
  module Schemas
    class VehicleBase
      include SchemaConcern

      schema_hidden true

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          slug: {type: :string, nullable: true},
          serial: {type: :string, nullable: true},
          alternativeNames: {type: :array, items: {type: :string}},
          boughtVia: {"$ref": "#/components/schemas/BoughtViaEnum"},
          boughtViaLabel: {type: :string},
          flagship: {type: :boolean},
          hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
          hangarGroups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}},
          loaner: {type: :boolean},
          model: {"$ref": "#/components/schemas/ModelMinimal"},
          modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
          modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
          modulePackage: {"$ref": "#/components/schemas/ModelModulePackage", nullable: true},
          nameVisible: {type: :boolean},
          paint: {"$ref": "#/components/schemas/ModelPaint", nullable: true},
          public: {type: :boolean},
          saleNotify: {type: :boolean},
          upgrade: {"$ref": "#/components/schemas/ModelUpgrade", nullable: true},
          wanted: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[
          id model wanted boughtVia loaner flagship public nameVisible saleNotify alternativeNames
          modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds
        ]
      })
    end
  end
end
