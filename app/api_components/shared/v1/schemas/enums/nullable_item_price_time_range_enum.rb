# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # ItemPriceTimeRangeEnum, or null where there is no rental.
        #
        # Nullable enums get a component of their own rather than
        # anyOf: [$ref, {type: :null}] — see NullableInventoryItemTypeEnum.
        class NullableItemPriceTimeRangeEnum
          include OpenapiRuby::Components::Base

          VALUES = (ItemPrice.time_ranges.keys + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ItemPrice.time_ranges.keys.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
