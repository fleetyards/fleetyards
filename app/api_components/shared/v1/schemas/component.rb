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
            retired: {type: :boolean},

            category: {type: :string},
            type: ::Shared::V1::Schemas::Enums::ComponentTypeEnum,
            subType: {type: :string},

            inventoryConsumption: {type: :string},

            grade: {type: :string},
            gradeLabel: {type: :string},
            size: {type: :string},
            class: ::Shared::V1::Schemas::Enums::ComponentClassEnum,
            itemClass: ::Shared::V1::Schemas::Enums::ComponentItemClassEnum,
            itemClassLabel: {type: :string},

            availability: Shared::V1::Schemas::ItemAvailability,

            manufacturer: {"$ref": "#/components/schemas/Manufacturer"},

            media: Shared::V1::Schemas::StoreImageMedia,

            typeData: {
              anyOf: [
                ::Shared::V1::Schemas::ComponentQuantumDrive,
                ::Shared::V1::Schemas::ComponentJumpDrive,
                ::Shared::V1::Schemas::ComponentArmor,
                ::Shared::V1::Schemas::CargoHold,
                ::Shared::V1::Schemas::FuelTank,
                ::Shared::V1::Schemas::ComponentThruster,
                ::Shared::V1::Schemas::ComponentWeapon,
                ::Shared::V1::Schemas::ComponentTractorBeam,
                ::Shared::V1::Schemas::ComponentShield,
                ::Shared::V1::Schemas::ComponentCooler,
                ::Shared::V1::Schemas::ComponentRadar,
                ::Shared::V1::Schemas::ComponentController,
                ::Shared::V1::Schemas::ComponentPowerPlant
              ]
            },

            hardpoints: {type: :array, items: ::Shared::V1::Schemas::Hardpoint},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug hidden retired availability media createdAt updatedAt]
        })
      end
    end
  end
end
