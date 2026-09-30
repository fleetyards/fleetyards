# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Distances in metres, times in seconds, angles in degrees.
      class ComponentMissile
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            damagePerShot: ComponentWeaponDamage,
            lockTime: {type: :number},
            lockRangeMin: {type: :number},
            lockRangeMax: {type: :number},
            lockAngle: {type: :number},
            trackingSignal: ::Shared::V1::Schemas::Enums::ComponentMissileTrackingSignalEnum,
            trackingSignalMin: {type: :number},
            signalResilienceMin: {type: :number},
            signalResilienceMax: {type: :number},
            dumbfire: {type: :boolean},
            speed: {type: :number},
            range: {type: :number},
            maxLifetime: {type: :number},
            boostPhaseDuration: {type: :number},
            terminalPhaseTime: {type: :number},
            terminalPhaseAngle: {type: :number},
            fuelTankSize: {type: :number},
            armTime: {type: :number},
            safetyDistance: {type: :number},
            blastRadiusMin: {type: :number},
            blastRadiusMax: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
