# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Component
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            scKey: {type: :string},
            scRef: {type: :string},

            hidden: {type: :boolean},

            category: {type: :string},
            type: {type: :string},
            subType: {type: :string},

            inventoryConsumption: {type: :string},

            grade: {type: :string},
            size: {type: :string},

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

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },

            typeData: {
              oneOf: [
                {"$ref": "#/components/schemas/ComponentQuantumDrive"},
                {"$ref": "#/components/schemas/ComponentCargoGrid"}
              ]
            },

            hardpoints: {type: :array, items: {"$ref": "#/components/schemas/Hardpoint"}},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug hidden availability media createdAt updatedAt]
        })
      end
    end
  end
end
