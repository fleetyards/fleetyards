# frozen_string_literal: true

module V1
  module Schemas
    class ShopCommodity < ShopCommodityMinimal
      include SchemaConcern

      schema({
        properties: {
          item: {
            oneOf: [{
              "$ref": "#/components/schemas/Model"
            }, {
              "$ref": "#/components/schemas/Component"
            }, {
              "$ref": "#/components/schemas/Commodity"
            }, {
              "$ref": "#/components/schemas/Equipment"
            }, {
              "$ref": "#/components/schemas/ModelModule"
            }, {
              "$ref": "#/components/schemas/ModelPaint"
            }]
          }
        },
        additionalProperties: false,
        required: %w[item]
      })
    end
  end
end
