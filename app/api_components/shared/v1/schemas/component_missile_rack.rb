# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentMissileRack
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # Seconds between two launches from the rack.
            launchDelay: {type: :number},
            # Whether the motor lights on the rack rather than after release.
            igniteOnPylon: {type: :boolean},
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
