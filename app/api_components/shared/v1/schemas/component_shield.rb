# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShield
        include Rswag::SchemaComponents::Component

        DAMAGE_TYPE_RANGE = {
          type: :object,
          properties: {
            min: {type: :number},
            max: {type: :number}
          },
          additionalProperties: false
        }.freeze

        DAMAGE_TYPE_MAP = {
          type: :object,
          properties: {
            physical: DAMAGE_TYPE_RANGE,
            energy: DAMAGE_TYPE_RANGE,
            distortion: DAMAGE_TYPE_RANGE,
            thermal: DAMAGE_TYPE_RANGE,
            biochemical: DAMAGE_TYPE_RANGE,
            stun: DAMAGE_TYPE_RANGE
          },
          additionalProperties: false
        }.freeze

        schema({
          type: :object,
          properties: {
            maxHealth: {type: :number},
            maxRegen: {type: :number},
            decayRatio: {type: :number},
            downedRegenDelay: {type: :number},
            damagedRegenDelay: {type: :number},
            resistance: DAMAGE_TYPE_MAP,
            absorption: DAMAGE_TYPE_MAP
          },
          additionalProperties: false,
          required: %w[maxHealth maxRegen]
        })
      end
    end
  end
end
