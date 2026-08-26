# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class Component
        include OpenapiRuby::Components::Base

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
            type: {"$ref": "#/components/schemas/ComponentTypeEnum"},
            subType: {type: :string},

            inventoryConsumption: {type: :string},

            grade: {type: :string},
            gradeLabel: {type: :string},
            size: {type: :string},
            class: {"$ref": "#/components/schemas/ComponentClassEnum"},
            itemClass: {"$ref": "#/components/schemas/ComponentItemClassEnum"},
            itemClassLabel: {type: :string},

            availability: Shared::V1::Schemas::ItemAvailability,

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: Shared::V1::Schemas::StoreImageMedia,

            typeData: {
              anyOf: [
                {"$ref": "#/components/schemas/ComponentQuantumDrive"},
                {"$ref": "#/components/schemas/ComponentJumpDrive"},
                {"$ref": "#/components/schemas/ComponentArmor"},
                {"$ref": "#/components/schemas/CargoHold"},
                {"$ref": "#/components/schemas/FuelTank"},
                {"$ref": "#/components/schemas/ComponentThruster"},
                {"$ref": "#/components/schemas/ComponentWeapon"},
                {"$ref": "#/components/schemas/ComponentTractorBeam"},
                {"$ref": "#/components/schemas/ComponentShield"},
                {"$ref": "#/components/schemas/ComponentCooler"},
                {"$ref": "#/components/schemas/ComponentRadar"},
                {"$ref": "#/components/schemas/ComponentController"},
                {"$ref": "#/components/schemas/ComponentPowerPlant"}
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
