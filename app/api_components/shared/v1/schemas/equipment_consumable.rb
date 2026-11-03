# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentConsumable
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            volume: {type: :number, description: "MicroSCU in one dose"},
            effects: {type: :array, items: ::Shared::V1::Schemas::EquipmentConsumableEffect}
          },
          additionalProperties: false
        })
      end
    end
  end
end
