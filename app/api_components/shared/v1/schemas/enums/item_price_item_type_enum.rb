# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ItemPriceItemTypeEnum
          include SchemaConcern

          schema({
            type: :string,
            enum: ["Model", "ModelModule", "ModelPaint", "Component"]
          })
        end
      end
    end
  end
end
