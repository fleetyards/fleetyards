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
            focus: {type: :string},
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

            media: Shared::V1::Schemas::ModelMedia,

            metrics: Shared::V1::Schemas::ModelMetrics,

            cargoHolds: {type: :array, items: {"$ref": "#/components/schemas/CargoHold"}},
            hydrogenFuelTanks: {type: :array, items: {"$ref": "#/components/schemas/FuelTank"}},
            quantumFuelTanks: {type: :array, items: {"$ref": "#/components/schemas/FuelTank"}},
            externalFuelTanks: {type: :array, items: {"$ref": "#/components/schemas/ExternalFuelTank"}},
            refuelBoom: {"$ref": "#/components/schemas/RefuelBoom"},

            onSale: {type: :boolean},
            playerOwnable: {type: :boolean},
            pledgePrice: {type: :number},
            pledgePriceLabel: {type: :string},
            price: {type: :number},
            priceLabel: {type: :string},
            productionNote: {type: :string},
            productionStatus: {"$ref": "#/components/schemas/ModelProductionStatusEnum"},
            rsiId: {type: :integer},
            rsiName: {type: :string},
            rsiSlug: {type: :string},

            speeds: Shared::V1::Schemas::ModelSpeeds,

            holo: {type: :string, deprecated: true},
            brochure: {type: :string, deprecated: true},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id name slug availability crew hasImages hasModules hasPaints hasUpgrades hasVideos
            inGame loaners manufacturer media metrics onSale playerOwnable speeds adiMap createdAt
            updatedAt
          ]
        })
      end
    end
  end
end
