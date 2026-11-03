# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentHeat
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            overheatTemperature: {type: :number},
            coolingPerSecond: {type: :number},
            coolingDelay: {type: :number},
            overheatFixTime: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
