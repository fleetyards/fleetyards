# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDrive
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            quantumFuelRequirement: {type: :number},
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
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
