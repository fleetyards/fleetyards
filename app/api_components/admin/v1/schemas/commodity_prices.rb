# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class CommodityPrices
        include SchemaConcern

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/CommodityPrice"},
          additionalProperties: false
        })
      end
    end
  end
end
