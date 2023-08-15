# frozen_string_literal: true

module V1
  module Schemas
    class VehiclePublicBase
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},
          slug: {type: :string, nullable: true},
          serial: {type: :string, nullable: true},
          hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
          hangarGroups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}},
          loaner: {type: :boolean},
          model: {"$ref": "#/components/schemas/ModelMinimal"},
          username: {type: :string, nullable: true},
          userAvatar: {type: :string, format: :uri, nullable: true},
          modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
          modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
          modulePackage: {"$ref": "#/components/schemas/ModelModulePackage", nullable: true},
          paint: {"$ref": "#/components/schemas/ModelPaint", nullable: true}
        },
        additionalProperties: false,
        required: %w[id model loaner modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds]
      })
    end
  end
end
