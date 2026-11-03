# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # What a mining gadget does to the rock it is stuck to.
      class EquipmentMining
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            modifiers: ::Shared::V1::Schemas::ComponentMiningModifiers,
            charges: {type: :integer}
          },
          additionalProperties: false
        })
      end
    end
  end
end
