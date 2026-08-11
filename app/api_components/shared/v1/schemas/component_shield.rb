# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShield
        include OpenapiRuby::Components::Base

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

        POWER_RANGE_ENTRY = {
          type: :object,
          properties: {
            start: {type: :number},
            modifier: {type: :number}
          },
          additionalProperties: false
        }.freeze

        POWER_RANGES = {
          type: :object,
          properties: {
            low: POWER_RANGE_ENTRY,
            medium: POWER_RANGE_ENTRY,
            high: POWER_RANGE_ENTRY
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
            absorption: DAMAGE_TYPE_MAP,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number}
          },
          additionalProperties: false,
          required: %w[maxHealth maxRegen]
        })
      end
    end
  end
end
