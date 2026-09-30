# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShield
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            maxHealth: {type: :number},
            maxRegen: {type: :number},
            decayRatio: {type: :number},
            downedRegenDelay: {type: :number},
            damagedRegenDelay: {type: :number},
            reservePoolInitialHealthRatio: {type: :number},
            reservePoolMaxHealthRatio: {type: :number},
            reservePoolRegenRateRatio: {type: :number},
            reservePoolDrainRateRatio: {type: :number},
            electricalChargeDamageResistance: {type: :number},
            stunParams: ComponentShieldStun,
            resistance: ComponentDamageTypeMap,
            absorption: ComponentDamageTypeMap,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          additionalProperties: false,
          required: %w[maxHealth maxRegen]
        })
      end
    end
  end
end
