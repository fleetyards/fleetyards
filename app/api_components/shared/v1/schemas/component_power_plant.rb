# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ComponentPowerPlant
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            powerBase: {type: :number},
            powerDraw: {type: :number}
          },
          additionalProperties: false
        })
      end
    end
  end
end
