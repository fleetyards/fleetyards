# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One thing a tool does. Which figures are set depends on its kind.
      class EquipmentToolAction
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            label: {type: :string},
            kind: ::Shared::V1::Schemas::Enums::EquipmentToolActionKindEnum,
            target: {type: :string},
            range: {type: :number},
            sensorRange: {type: :number},
            optimalRange: {type: :number},
            doseRate: {type: :number},
            ammoPerDose: {type: :number},
            batteryDrain: {type: :number},
            minForce: {type: :number},
            maxForce: {type: :number},
            minDistance: {type: :number},
            maxDistance: {type: :number},
            fullStrengthDistance: {type: :number},
            maxAngle: {type: :number},
            maxVolume: {type: :number},
            maxSpeed: {type: :number},
            healthRate: {type: :number},
            damageMapRate: {type: :number},
            materialEfficiency: {type: :number},
            healthToAmmoRatio: {type: :number},
            rampUpTime: {type: :number},
            power: {type: :number},
            chargeUpTime: {type: :number},
            resourceRate: {type: :number},
            minPrime: {type: :number},
            maxPrime: {type: :number},
            primeTime: {type: :number},
            overloadDuration: {type: :number},
            coneAngle: {type: :number},
            maxRadius: {type: :number}
          },
          additionalProperties: false,
          required: %w[kind]
        })
      end
    end
  end
end
