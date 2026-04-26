# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShield
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            maxHealth: {type: :number},
            maxRegen: {type: :number},
            decayRatio: {type: :number},
            downedRegenDelay: {type: :number},
            damagedRegenDelay: {type: :number}
          },
          additionalProperties: false,
          required: %w[maxHealth maxRegen]
        })
      end
    end
  end
end
