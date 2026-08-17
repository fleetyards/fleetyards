# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDrive
        include OpenapiRuby::Components::Base

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
            quantumFuelRequirement: {type: :number},
            quantumFuelConsumption: {type: :number},
            jumpRange: {type: :number},
            disconnectRange: {type: :number},
            driveSpeed: {type: :number},
            cooldownTime: {type: :number},
            stageOneAccelRate: {type: :number},
            stageTwoAccelRate: {type: :number},
            engageSpeed: {type: :number},
            calibrationRate: {type: :number},
            minCalibrationRequirement: {type: :number},
            maxCalibrationRequirement: {type: :number},
            calibrationProcessAngleLimit: {type: :number},
            calibrationWarningAngleLimit: {type: :number},
            calibrationDelayInSeconds: {type: :number},
            spoolUpTime: {type: :number},
            splineJumpParams: {
              "$ref": "#/components/schemas/ComponentQuantumDriveJump"
            },
            quantumBoostParams: {
              "$ref": "#/components/schemas/ComponentQuantumDriveBoost"
            },
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: POWER_RANGES,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
