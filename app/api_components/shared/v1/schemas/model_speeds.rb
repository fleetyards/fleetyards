# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelSpeeds
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            groundAcceleration: {type: :number},
            groundDecceleration: {type: :number},
            groundMaxSpeed: {type: :number},
            groundReverseSpeed: {type: :number},
            maxSpeed: {type: :number},
            pitch: {type: :number},
            pitchBoosted: {type: :number},
            roll: {type: :number},
            rollBoosted: {type: :number},
            scmSpeed: {type: :number},
            scmSpeedBoosted: {type: :number},

            # What the thrusters give, in m/s^2, and what that means in seconds.
            # Null for a ship whose loadout the export has not described -- a
            # concept ship, or a catalogue loaded before the export named a
            # thruster's type.
            mainAcceleration: {type: [:number, :null]},
            retroAcceleration: {type: [:number, :null]},
            secondsToScmSpeed: {type: [:number, :null]},
            secondsToStopFromScmSpeed: {type: [:number, :null]},
            reverseSpeedBoosted: {type: :number},
            yaw: {type: :number},
            yawBoosted: {type: :number}
          },
          additionalProperties: false

        })
      end
    end
  end
end
