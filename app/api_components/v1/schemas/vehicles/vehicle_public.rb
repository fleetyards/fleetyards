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
            publicLogEntriesCount: {type: :integer},
            # The dedication plaque, sent only for a public vehicle.
            dedication: {type: [:string, :null]},
            dedicationVerse: {type: [:string, :null]},
            launchedOn: {type: [:string, :null], format: :date},
            launchPort: {type: [:string, :null]},
            launchPortLocation: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
            affiliation: {type: [:string, :null]},
            plaqueCaptain: {type: [:string, :null]},
            operationsGroup: ::V1::Schemas::Enums::NullableVehicleOperationsGroupEnum,
            manufacturerShortName: {type: [:string, :null]},
            manufacturerCode: {type: [:string, :null]},
            # The style the plaque is drawn in. A supporter style outlasts the
            # support until the plaque is next edited.
            plaqueStyle: ::V1::Schemas::Enums::VehiclePlaqueStyleEnum,
            shipyard: {type: [:string, :null]},
            bundled: {type: :boolean},
            bundledParent: VehicleBundledParent,
            model: {"$ref": "#/components/schemas/Model"},
            username: {type: :string},
            userDisplayName: {type: :string},
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
            image: ::Shared::V1::Schemas::MediaFile,
            activeLoadout: ::V1::Schemas::Vehicles::VehicleLoadoutMinimal,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id model loaner bundled publicLogEntriesCount modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds
            createdAt updatedAt
          ]
        })
      end
    end
  end
end
