# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class CommodityPriceTimeRangeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: CommodityRentalPrice.time_ranges.keys
          })
        end
      end
    end
  end
end
