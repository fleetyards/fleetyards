# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehiclePublic
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            serial: {type: :string},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            hangarGroups: {type: :array, items: ::V1::Schemas::Hangar::Groups::HangarGroupPublic},
            loaner: {type: :boolean},
            bundled: {type: :boolean},
            bundledParent: VehicleBundledParent,
            model: {"$ref": "#/components/schemas/Model"},
            username: {type: :string},
            userAvatar: {type: :string, format: :uri},
            userRsiHandle: {type: :string},
            # Only the fleet-scoped vehicle endpoints send these; the public hangar
            # and public fleet payloads carry no contact details for an owner.
            userDiscordProfileUrl: {type: :string, format: :uri},
            userCitizenidProfileUrl: {type: :string, format: :uri},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            modulePackage: {"$ref": "#/components/schemas/ModelModulePackage"},
            upgrade: {"$ref": "#/components/schemas/ModelUpgrade"},
            paint: {"$ref": "#/components/schemas/ModelPaint"},
            activeLoadout: ::V1::Schemas::Vehicles::VehicleLoadoutMinimal,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id model loaner bundled modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds
            createdAt updatedAt
          ]
        })
      end
    end
  end
end
