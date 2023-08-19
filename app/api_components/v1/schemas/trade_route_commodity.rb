# frozen_string_literal: true

module V1
  module Schemas
    class TradeRouteCommodity
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          type: {"$ref": "#/components/schemas/CommodityTypeEnum"}
        },
        additionalProperties: false,
        required: %w[name slug type]
      })
    end
  end
end
