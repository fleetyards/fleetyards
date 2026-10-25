# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class Vehicle
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            serial: {type: :string},
            alternativeNames: {type: :array, items: {type: :string}},
            boughtVia: ::Shared::V1::Schemas::Enums::BoughtViaEnum,
            boughtViaLabel: {type: :string},
            flagship: {type: :boolean},
            hangarGroupIds: {type: :array, items: {type: :string, format: :uuid}},
            hangarGroups: {type: :array, items: {"$ref": "#/components/schemas/HangarGroup"}},
            loaner: {type: :boolean},
            bundled: {type: :boolean},
            bundledParent: VehicleBundledParent,
            model: {"$ref": "#/components/schemas/Model"},
            modelModuleIds: {type: :array, items: {type: :string, format: :uuid}},
            # The hull plus the cargo modules fitted: the active loadout's, or the
            # ones the ship comes with.
            cargo: {type: :number},
            # Sent without a loadout, when the ship's cargo modules would add more.
            cargoWithModules: {type: :number},
            # The guns fitted, by size: the active loadout's, or the ones the
            # ship comes with.
            maxWeaponSize: {type: [:integer, :null]},
            weaponSizes: {type: :array, items: ::V1::Schemas::Vehicles::WeaponSizeCount},
            # Firepower without anyone's pips: alpha and burst with the guns
            # powered, sustained at one weapon pip and at the most the plant gives.
            alpha: {type: [:number, :null]},
            burstDps: {type: [:number, :null]},
            sustainedDpsMin: {type: [:number, :null]},
            sustainedDpsMax: {type: [:number, :null]},
            modelUpgradeIds: {type: :array, items: {type: :string, format: :uuid}},
            modelPaintIds: {type: :array, items: {type: :string, format: :uuid}},
            modulePackage: {"$ref": "#/components/schemas/ModelModulePackage"},
            nameVisible: {type: :boolean},
            public: {type: :boolean},
            saleNotify: {type: :boolean},
            logEntriesPublicByDefault: {type: :boolean},
            location: {type: [:string, :null]},
            linkedLocation: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
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
            # The language the plaque is printed in; English when unset.
            plaqueLocale: ::V1::Schemas::Enums::NullableVehiclePlaqueLocaleEnum,
            shipyard: {type: [:string, :null]},
            image: ::Shared::V1::Schemas::MediaFile,
            # The editor's: whether `image` is an upload, and what is picked.
            imageUploaded: {type: :boolean},
            pictureType: ::V1::Schemas::Enums::NullableVehiclePictureTypeEnum,
            pictureId: {type: [:string, :null], format: :uuid},
            upgrade: {"$ref": "#/components/schemas/ModelUpgrade"},
            wanted: {type: :boolean},
            hiddenByUser: {type: :boolean},
            activeLoadout: ::V1::Schemas::Vehicles::VehicleLoadoutMinimal,
            # Only the single-vehicle endpoint sends these: the fleets the ship
            # is listed in, as far as its owner is still a member.
            fleets: {type: :array, items: ::V1::Schemas::Vehicles::VehicleFleet},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id model wanted hiddenByUser loaner bundled flagship public nameVisible saleNotify logEntriesPublicByDefault alternativeNames
            modelUpgradeIds hangarGroupIds hangarGroups modelModuleIds modelPaintIds weaponSizes createdAt updatedAt
          ]
        })
      end
    end
  end
end
