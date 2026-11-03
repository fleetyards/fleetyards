# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a mining gadget or module does to the rock or the laser.
      class EquipmentMining
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modifiers: ::Shared::V1::Schemas::ComponentMiningModifiers,
            charges: {type: :integer},
            fracturePower: {type: :number},
            extractionPower: {type: :number},
            activation: {type: :string},
            duration: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
