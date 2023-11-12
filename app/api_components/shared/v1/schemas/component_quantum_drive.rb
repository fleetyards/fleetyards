# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDrive
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            fuelRate: {type: :number},
            jumpRange: {type: :number},
            standardJump: {
              "$ref": "#/components/schemas/ComponentQuantumDriveJump"
            },
            splineJump: {
              "$ref": "#/components/schemas/ComponentQuantumDriveJump"
            }
          },
          additionalProperties: false,
          required: %w[fuelRate jumpRange standardJump splineJump]
        })
      end
    end
  end
end
