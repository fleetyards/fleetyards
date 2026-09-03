# frozen_string_literal: true

module V1
  module Schemas
    module Commodities
      class CommodityPricePointsList
        include OpenapiRuby::Components::Base

        schema({
          type: :array,
          items: {"$ref": "#/components/schemas/CommodityPricePoint"}
        })
      end
    end
  end
end
