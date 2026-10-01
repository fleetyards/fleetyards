# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentShieldController
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            faceType: ::Shared::V1::Schemas::Enums::ComponentShieldFaceTypeEnum,
            maxReallocation: {type: :number},
            # Seconds before a quadrant shield can shift strength again.
            reconfigurationCooldown: {type: :number},
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
