# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class EquipmentTypeEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Equipment::EQUIPMENT_TYPES,
            "x-enumNames": ::Equipment::EQUIPMENT_TYPES.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
