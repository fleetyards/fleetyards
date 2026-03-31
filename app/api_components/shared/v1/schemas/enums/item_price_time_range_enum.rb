# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ItemPriceTimeRangeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ItemPrice.time_ranges.keys,
            "x-enumNames": ItemPrice.time_ranges.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
