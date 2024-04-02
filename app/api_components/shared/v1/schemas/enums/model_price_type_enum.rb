# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelPriceTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ::ModelPrice.price_types.keys
          })
        end
      end
    end
  end
end
