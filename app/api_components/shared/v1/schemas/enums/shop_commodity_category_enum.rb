# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ShopCommodityCategoryEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::ShopCommodity.commodity_item_types.map(&:downcase)
          })
        end
      end
    end
  end
end
