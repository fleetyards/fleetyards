# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentFitPortType
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: {type: :string, description: "The game's item type the port takes, e.g. Char_Armor_Arms or WeaponPersonal"},
            subTypes: {type: :array, items: {type: :string}, description: "The sub types it takes of that type; any when absent"}
          },
          additionalProperties: false,
          required: %w[type]
        })
      end
    end
  end
end
