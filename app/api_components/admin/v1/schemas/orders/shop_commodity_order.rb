# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Orders
        class ShopCommodityOrder
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              name: {"$ref": "#/components/schemas/OrderDirectionEnum"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
