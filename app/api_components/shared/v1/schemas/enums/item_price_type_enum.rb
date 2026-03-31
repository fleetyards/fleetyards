# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ItemPriceTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::ItemPrice.price_types.keys,
            "x-enumNames": ::ItemPrice.price_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
