# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentJumpDrive
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            alignmentRate: {type: :number},
            alignmentDecayRate: {type: :number},
            tuningRate: {type: :number},
            tuningDecayRate: {type: :number},
            fuelUsageEfficiencyMultiplier: {type: :number},
            # Tunnel flight, in m/s: the speed a ship drops to on leaving the
            # tunnel and the top speed it can hold inside it.
            exitSpeed: {type: :number},
            maxTunnelSpeed: {type: :number},
            respoolTime: {type: :number},
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
