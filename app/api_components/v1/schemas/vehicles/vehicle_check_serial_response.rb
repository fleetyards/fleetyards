# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleCheckSerialResponse
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            serialTaken: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[serialTaken]
        })
      end
    end
  end
end
