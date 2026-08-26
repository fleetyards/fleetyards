# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        # Only ever used in a nullable position, so there is no non-null
        # sibling. See NullableInventoryItemTypeEnum for why nullable enums are
        # their own component instead of anyOf: [$ref, {type: :null}].
        class NullableEquipmentCoreCompatibilityEnum
          include OpenapiRuby::Components::Base

          VALUES = (::Equipment.core_compatibilities.keys + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::Equipment.core_compatibilities.keys.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
