# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Nullable enums get a component of their own rather than
      # anyOf: [$ref, {type: :null}].
      class NullableVehiclePictureTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = (::Vehicle::PICTURE_TYPES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::Vehicle::PICTURE_TYPES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
