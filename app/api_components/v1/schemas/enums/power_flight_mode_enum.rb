# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class PowerFlightModeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::VehicleLoadout::POWER_MODES,
          "x-enumNames": ::VehicleLoadout::POWER_MODES.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
