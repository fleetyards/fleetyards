# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class EquipmentTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Equipment.equipment_types.keys
          })
        end
      end
    end
  end
end
