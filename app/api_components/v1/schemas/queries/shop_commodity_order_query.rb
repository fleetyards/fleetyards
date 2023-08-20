# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class ShopCommodityOrderQuery
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string, enum: ["asc", "desc"]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
