# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class EquipmentInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              description: {type: [:string, :null]},
              equipmentType: {type: [:string, :null]},
              itemType: {type: [:string, :null]},
              subType: {type: [:string, :null]},
              weaponClass: {type: [:string, :null]},
              # Enumerated rather than free strings: these three are Rails enums,
              # and an unknown value raises ArgumentError on assign instead of
              # failing validation. The controller catches that too.
              slot: {"$ref": "#/components/schemas/NullableEquipmentSlotEnum"},
              size: {type: [:string, :null]},
              grade: {type: [:string, :null]},
              rateOfFire: {type: [:number, :null]},
              range: {type: [:number, :null]},
              storage: {type: [:number, :null]},
              volume: {type: [:number, :null]},
              damageReduction: {type: [:number, :null]},
              temperatureRating: {type: [:string, :null]},
              radiationProtection: {type: [:number, :null]},
              radiationScrubRate: {type: [:number, :null]},
              gForceTolerance: {type: [:number, :null]},
              coreCompatibility: {"$ref": "#/components/schemas/NullableEquipmentCoreCompatibilityEnum"},
              backpackCompatibility: {"$ref": "#/components/schemas/NullableEquipmentBackpackCompatibilityEnum"},
              manufacturerId: {type: :string, format: :uuid},
              hidden: {type: :boolean},
              storeImage: {type: [:string, :null]},
              scKey: {type: [:string, :null]},
              scRef: {type: [:string, :null]}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
