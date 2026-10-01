# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentBoostCapacitor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            capacity: {type: :number},
            # Refill per second, once `regenDelay` seconds have passed since
            # the last boost.
            regenPerSecond: {type: :number},
            regenDelay: {type: :number},
            # Spent per second while boosting, on top of each other: idle, and
            # while thrusting or turning.
            idleCost: {type: :number},
            linearCost: {type: :number},
            angularCost: {type: :number},
            # Share of the capacity that must be back before boost can start.
            thresholdRatio: {type: :number},
            preDelay: {type: :number},
            rampUpTime: {type: :number},
            rampDownTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
