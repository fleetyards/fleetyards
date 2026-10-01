# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentQuantumJammer
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            jammerRange: {type: :number},
            maxPowerDraw: {type: :number},
            greenZoneCheckRange: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
