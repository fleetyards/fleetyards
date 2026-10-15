# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class VehicleLoadoutItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            slot: {type: :string, description: "The module hardpoint's sc_name on the hull"},
            modelModuleId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[slot modelModuleId]
        })
      end
    end
  end
end
