# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Modules
        class ModelModule
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              description: {type: :string},

              scKey: {type: :string},

              metrics: {
                type: :object,
                properties: {
                  cargo: {type: :number}
                },
                additionalProperties: false
              },

              cargoHolds: {type: :array, items: {"$ref": "#/components/schemas/CargoHold"}},

              availability: {
                type: :object,
                properties: {
                  boughtAt: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/ItemPrice"}
                  },
                  soldAt: {
                    type: :array,
                    items: {"$ref": "#/components/schemas/ItemPrice"}
                  }
                },
                additionalProperties: false,
                required: %w[boughtAt soldAt]
              },

              media: {
                type: :object,
                properties: {
                  storeImage: {"$ref": "#/components/schemas/MediaImage"}
                },
                additionalProperties: false
              },
              pledgePrice: {type: :number},
              productionStatus: {type: :string},

              manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name availability media createdAt updatedAt]
          })
        end
      end
    end
  end
end
