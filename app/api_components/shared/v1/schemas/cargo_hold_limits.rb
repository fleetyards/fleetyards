# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class CargoHoldLimits
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            min: {"$ref": "#/components/schemas/CargoHoldLimit"},
            max: {"$ref": "#/components/schemas/CargoHoldLimit"}
          },
          additionalProperties: false,
          required: %w[min]
        })
      end
    end
  end
end
