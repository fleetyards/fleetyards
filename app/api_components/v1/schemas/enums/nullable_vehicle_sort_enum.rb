# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # See NullableInventoryItemTypeEnum for why nullable enums are their own
      # component instead of anyOf: [$ref, {type: :null}].
      class NullableVehicleSortEnum
        include OpenapiRuby::Components::Base

        VALUES = (Vehicle::ALLOWED_SORTING_PARAMS + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": Vehicle::ALLOWED_SORTING_PARAMS.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
