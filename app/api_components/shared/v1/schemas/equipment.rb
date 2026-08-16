# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Equipment
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            description: {type: [:string, :null]},

            equipmentType: {"$ref": "#/components/schemas/EquipmentTypeEnum"},
            itemType: {type: [:string, :null]},
            subType: {type: [:string, :null]},
            weaponClass: {type: [:string, :null]},

            slot: {type: [:string, :null]},
            size: {type: [:string, :null]},
            grade: {type: [:string, :null]},
            rateOfFire: {type: [:number, :null]},
            range: {type: [:number, :null]},
            storage: {type: [:number, :null]},

            damageReduction: {type: [:number, :null]},
            temperatureRating: {type: [:string, :null]},
            radiationProtection: {type: [:number, :null]},
            radiationScrubRate: {type: [:number, :null]},
            gForceTolerance: {type: [:number, :null]},
            coreCompatibility: {type: [:string, :null]},
            backpackCompatibility: {type: [:string, :null]},

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

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

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug availability createdAt updatedAt]
        })
      end
    end
  end
end
