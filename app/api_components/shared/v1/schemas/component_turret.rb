# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentTurret
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Top turn rate per axis, in degrees per second.
            yawSpeed: {type: :number},
            pitchSpeed: {type: :number},
            # Angle limits per axis, in degrees from centre. A limit that
            # changes with the turret's rotation reports the widest it gets and
            # sets the matching `*LimitsVary`.
            minYaw: {type: :number},
            maxYaw: {type: :number},
            yawLimitsVary: {type: :boolean},
            minPitch: {type: :number},
            maxPitch: {type: :number},
            pitchLimitsVary: {type: :boolean},
            control: ::Shared::V1::Schemas::Enums::ComponentTurretControlEnum,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
