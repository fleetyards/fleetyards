# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One effect of a whole dose.
      class EquipmentConsumableEffect
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            kind: ::Shared::V1::Schemas::Enums::EquipmentConsumableEffectKindEnum,
            amount: {type: :number},
            stat: {type: :string},
            buff: {type: :string},
            duration: {type: :number}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
