# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDriveJump
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
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
            spoolUpTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
