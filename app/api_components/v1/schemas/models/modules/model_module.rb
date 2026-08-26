# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Modules
        class ModelModule
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              hasStoreImage: {type: :boolean},

              scKey: {type: :string},

              metrics: {
                type: :object,
                properties: {
                  cargo: {type: :number}
                },
                additionalProperties: false
              },

              cargoHolds: {type: :array, items: {"$ref": "#/components/schemas/CargoHold"}},

              availability: Shared::V1::Schemas::ItemAvailability,

              media: Shared::V1::Schemas::StoreImageMedia,
              pledgePrice: {type: :number},
              productionStatus: {type: :string},

              manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

              slot: {type: :string, description: "Module slot identifier (hardpoint sc_name). Present when fetched via a model's modules endpoint."},

              hardpoints: {type: :array, items: {"$ref": "#/components/schemas/Hardpoint"}},

              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug availability media createdAt updatedAt]
          })
        end
      end
    end
  end
end
