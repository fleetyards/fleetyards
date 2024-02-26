# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class CommodityPricePathEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: %w[buy sell rental]
          })
        end
      end
    end
  end
end
