# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # See NullableInventoryItemTypeEnum for why nullable enums are their own
      # component instead of anyOf: [$ref, {type: :null}].
      class NullableRsiHandleVerifiedViaEnum
        include OpenapiRuby::Components::Base

        VALUES = (::User.defined_enums.fetch("rsi_handle_verified_via").keys + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::User.defined_enums.fetch("rsi_handle_verified_via").keys.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
