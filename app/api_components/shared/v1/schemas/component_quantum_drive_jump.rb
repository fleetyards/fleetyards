# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDriveJump
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            speed: {type: :number},
            stage1AccelerationRate: {type: :number},
            stage2AccelerationRate: {type: :number},
            spoolUpTime: {type: :number},
            cooldown: {type: :number}
          },
          additionalProperties: false,
          required: %w[speed stage1AccelerationRate stage2AccelerationRate spoolUpTime cooldown]
        })
      end
    end
  end
end
