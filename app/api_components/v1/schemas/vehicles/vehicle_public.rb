# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehiclePublic
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            serial: {type: :string},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            hangarGroups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroupPublic"}},
            loaner: {type: :boolean},
            model: {"$ref": "#/components/schemas/Model"},
            username: {type: :string},
            userAvatar: {type: :string, format: :uri},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            modulePackage: {"$ref": "#/components/schemas/ModelModulePackage"},
            paint: {"$ref": "#/components/schemas/ModelPaint"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id model loaner modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds createdAt
            updatedAt
          ]
        })
      end
    end
  end
end
