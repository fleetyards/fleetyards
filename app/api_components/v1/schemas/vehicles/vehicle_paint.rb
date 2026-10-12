# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehiclePaint
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            owned: {type: :boolean},
            applied: {type: :boolean},
            paint: {"$ref": "#/components/schemas/ModelPaint"}
          },
          additionalProperties: false,
          required: %w[owned applied paint]
        })
      end
    end
  end
end
