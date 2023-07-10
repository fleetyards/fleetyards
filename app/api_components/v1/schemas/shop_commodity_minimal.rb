# frozen_string_literal: true

module V1
  module Schemas
    class ShopCommodityMinimal < ShopCommodity
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
          },
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[item createdAt updatedAt]
      })
    end
  end
end
