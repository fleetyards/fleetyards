# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumDriveBoost
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            maxBoostSpeed: {type: :number},
            timeToMaxBoostSpeed: {type: :number},
            boostUseTime: {type: :number},
            boostRechargeTime: {type: :number},
            stopTime: {type: :number},
            minJumpDistance: {type: :number},
            ifcsHandoverDownTime: {type: :number},
            ifcsHandoverRespoolTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
