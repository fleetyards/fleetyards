# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentThruster
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            thrustCapacity: {type: :number},
            thrusterType: {type: :string},
            thrusterClass: ::Shared::V1::Schemas::Enums::ThrusterClassEnum,
            fuelBurnRatePer10KNewton: {type: :number},
            vtolOnly: {type: :boolean},
            gimbal: ComponentThrusterGimbal,
            powerConsumption: {type: :number},
            powerMinimumFraction: {type: :number},
            powerRanges: ComponentPowerRanges,
            signatureEm: {type: :number},
            signatureIr: {type: :number}
          },
          additionalProperties: false,
          required: %w[thrustCapacity thrusterType fuelBurnRatePer10KNewton]
        })
      end
    end
  end
end
