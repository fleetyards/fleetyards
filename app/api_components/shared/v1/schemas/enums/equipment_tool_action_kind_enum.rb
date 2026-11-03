# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What a tool's action does.
        class EquipmentToolActionKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ScData::Parser::GearStats::TOOL_ACTION_KINDS

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
