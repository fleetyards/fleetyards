# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class PowerPreset
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            mode: ::V1::Schemas::Enums::PowerFlightModeEnum,
            overrides: {
              type: :array,
              items: ::V1::Schemas::Vehicles::PowerPresetOverride,
              description: "Pips set by hand; a power port left out follows the automatic balance"
            }
          },
          additionalProperties: false,
          required: %w[name mode overrides]
        })
      end
    end
  end
end
