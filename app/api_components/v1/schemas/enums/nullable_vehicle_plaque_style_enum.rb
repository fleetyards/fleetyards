# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Nullable enums get a component of their own rather than
      # anyOf: [$ref, {type: :null}].
      class NullableVehiclePlaqueStyleEnum
        include OpenapiRuby::Components::Base

        VALUES = (::Vehicle::PLAQUE_STYLES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::Vehicle::PLAQUE_STYLES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
