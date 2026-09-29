# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # See NullableInventoryItemTypeEnum for why nullable enums are their own
      # component instead of anyOf: [$ref, {type: :null}].
      class NullableUserRsiVerificationStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = (::User.rsi_verification_statuses.keys + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::User.rsi_verification_statuses.keys.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
