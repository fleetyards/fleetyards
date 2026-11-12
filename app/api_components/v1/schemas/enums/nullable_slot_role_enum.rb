# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class NullableSlotRoleEnum
        include OpenapiRuby::Components::Base

        VALUES = (::SlotRole::ROLES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::SlotRole::ROLES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
