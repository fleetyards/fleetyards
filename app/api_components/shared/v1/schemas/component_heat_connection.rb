# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # As ComponentPowerConnection, for heat.
      class ComponentHeatConnection
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            thermalEnergyBase: {type: :number},
            thermalEnergyDraw: {type: :number},
            coolingRate: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
