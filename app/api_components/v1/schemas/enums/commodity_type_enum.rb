# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class CommodityTypeEnum
        include SchemaConcern

        schema({
          type: :string,
          enum: ::Commodity.commodity_types.keys
        })
      end
    end
  end
end
