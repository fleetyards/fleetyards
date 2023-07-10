# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ShopTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::Shop.shop_types.keys
          })
        end
      end
    end
  end
end
