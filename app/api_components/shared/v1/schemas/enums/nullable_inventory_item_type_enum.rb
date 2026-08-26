# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # oasdiff does not resolve enum values through anyOf, so a nullable
        # property gets its own component rather than
        # anyOf: [$ref, {type: :null}] — otherwise every value reads as removed.
        class NullableInventoryItemTypeEnum
          include OpenapiRuby::Components::Base

          VALUES = (InventoryItemTypeEnum::VALUES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": InventoryItemTypeEnum::VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
