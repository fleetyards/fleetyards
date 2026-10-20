# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class PowerPreset
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, maxLength: ::VehicleLoadout::MAX_POWER_PRESET_NAME},
            scm: {
              type: :array,
              items: ::V1::Schemas::Vehicles::PowerPresetOverride,
              description: "Pips set by hand in SCM; a power port left out follows the automatic balance"
            },
            nav: {
              type: :array,
              items: ::V1::Schemas::Vehicles::PowerPresetOverride,
              description: "Pips set by hand in NAV; a power port left out follows the automatic balance"
            }
          },
          additionalProperties: false,
          required: %w[name scm nav]
        })
      end
    end
  end
end
