# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetEventRecurrenceIntervalEnum
        include OpenapiRuby::Components::Base

        VALUES = ::FleetEvent::RECURRENCE_INTERVALS.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
