# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class EquipmentTypeEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Equipment.equipment_types.keys,
            "x-enumNames": ::Equipment.equipment_types.keys.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
