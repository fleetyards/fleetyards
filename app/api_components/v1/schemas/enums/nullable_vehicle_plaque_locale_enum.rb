# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Nullable enums get a component of their own rather than
      # anyOf: [$ref, {type: :null}].
      class NullableVehiclePlaqueLocaleEnum
        include OpenapiRuby::Components::Base

        VALUES = (::Vehicle::PLAQUE_LOCALES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::Vehicle::PLAQUE_LOCALES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
