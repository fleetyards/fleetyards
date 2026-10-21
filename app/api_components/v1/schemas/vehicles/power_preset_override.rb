# frozen_string_literal: true

module V1
  module Schemas
    module Vehicles
      class PowerPresetOverride
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            portPath: {type: :string},
            pips: {type: :integer, minimum: 0, maximum: ::VehicleLoadout::MAX_POWER_PRESET_PIPS}
          },
          additionalProperties: false,
          required: %w[portPath pips]
        })
      end
    end
  end
end
