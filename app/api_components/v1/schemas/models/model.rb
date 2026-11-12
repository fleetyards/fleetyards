# frozen_string_literal: true

module V1
  module Schemas
    module Models
      class Model
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            scIdentifier: {type: :string},
            inGame: {type: :boolean},
            name: {type: :string},
            slug: {type: :string},

            availability: Shared::V1::Schemas::ModelAvailability,

            classification: {type: :string},
            classificationLabel: {type: :string},

            adiMap: {type: :boolean, default: false},

            crew: Shared::V1::Schemas::ModelCrew,

            description: {type: :string},
            erkulIdentifier: {type: :string},
            foci: {type: :array, items: ::Shared::V1::Schemas::Enums::ModelFocusEnum},
            fociLabels: {type: :array, items: {type: :string}},
            stealth: {type: :boolean},
            hasImages: {type: :boolean},
            hasModules: {type: :boolean},
            hasPaints: {type: :boolean},
            hasUpgrades: {type: :boolean},
            hasVideos: {type: :boolean},
            lastUpdatedAt: {type: :string, format: "date-time"},
            lastUpdatedAtLabel: {type: :string},

            links: Shared::V1::Schemas::ModelLinks,

            loaners: {
              type: :array,
              items: {"$ref": "#/components/schemas/ModelLoaner"}
            },

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            holoToScale: {type: :boolean},

            media: ::V1::Schemas::ModelMedia,

            metrics: Shared::V1::Schemas::ModelMetrics,

            cargoHolds: {type: :array, items: ::Shared::V1::Schemas::CargoHold},
            hydrogenFuelTanks: {type: :array, items: ::Shared::V1::Schemas::FuelTank},
            quantumFuelTanks: {type: :array, items: ::Shared::V1::Schemas::FuelTank},
            externalFuelTanks: {type: :array, items: ::Shared::V1::Schemas::ExternalFuelTank},
            storageContainers: {type: :array, items: ::Shared::V1::Schemas::StorageContainer},
            weaponRacks: {type: :array, items: ::Shared::V1::Schemas::WeaponRack},
            refuelBoom: ::Shared::V1::Schemas::RefuelBoom,
            # What the ship does for another ship landed in its hangar or on its pads.
            landingServices: {type: :array, items: ::Shared::V1::Schemas::Enums::LandingServiceEnum},
            servicingAreas: {type: :array, items: ::Shared::V1::Schemas::ServicingArea},

            onSale: {type: :boolean},
            playerOwnable: {type: :boolean},
            ingameOnly: {type: :boolean},

            # Curated: false for ships too large, or carrying cargo outside the
            # hull, to set down on a planet or moon. They trade and fly
            # missions at stations only.
            canLandOnPlanets: {type: :boolean},
            pledgePrice: {type: :number},
            pledgePriceLabel: {type: :string},
            price: {type: :number},
            priceLabel: {type: :string},
            productionNote: {type: :string},
            productionStatus: ::Shared::V1::Schemas::Enums::ModelProductionStatusEnum,
            rsiId: {type: :integer},
            rsiName: {type: :string},
            rsiSlug: {type: :string},

            speeds: Shared::V1::Schemas::ModelSpeeds,

            # The ship as it comes. Firepower without anyone's pips: alpha and
            # burst with the guns powered, sustained at one weapon pip and at the
            # most the plant gives.
            maxWeaponSize: {type: [:integer, :null]},
            weaponSizes: {type: :array, items: ::Shared::V1::Schemas::WeaponSizeCount},
            alpha: {type: [:number, :null]},
            burstDps: {type: [:number, :null]},
            sustainedDpsMin: {type: [:number, :null]},
            sustainedDpsMax: {type: [:number, :null]},

            holo: {type: :string, deprecated: true},
            brochure: {type: :string, deprecated: true},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos
            inGame ingameOnly canLandOnPlanets loaners manufacturer media metrics onSale playerOwnable speeds adiMap createdAt
            updatedAt foci fociLabels stealth
          ]
        })
      end
    end
  end
end
