# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # See NullableInventoryItemTypeEnum for why nullable enums are their own
      # component instead of anyOf: [$ref, {type: :null}].
      class NullableFleetEventRecurrenceIntervalEnum
        include OpenapiRuby::Components::Base

        VALUES = (FleetEventRecurrenceIntervalEnum::VALUES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": FleetEventRecurrenceIntervalEnum::VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
