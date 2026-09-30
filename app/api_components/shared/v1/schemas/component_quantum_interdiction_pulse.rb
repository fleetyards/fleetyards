# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumInterdictionPulse
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            chargeTimeSecs: {type: :number},
            dischargeTimeSecs: {type: :number},
            cooldownTimeSecs: {type: :number},
            radiusMeters: {type: :number},
            decreaseChargeRateTimeSeconds: {type: :number},
            increaseChargeRateTimeSeconds: {type: :number},
            activationPhaseDurationSeconds: {type: :number},
            disperseChargeTimeSeconds: {type: :number},
            maxPowerDraw: {type: :number},
            stopChargingPowerDrawFraction: {type: :number},
            maxChargeRatePowerDrawFraction: {type: :number},
            activePowerDrawFraction: {type: :number},
            tetheringPowerDrawFraction: {type: :number},
            greenZoneCheckRange: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
