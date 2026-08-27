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
            splineJumpParams: ::Shared::V1::Schemas::ComponentQuantumDriveJump,
            quantumBoostParams: ::Shared::V1::Schemas::ComponentQuantumDriveBoost,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
