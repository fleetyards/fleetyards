# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Whether a dose heals, moves a body stat, or applies a buff.
        class EquipmentConsumableEffectKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ScData::Parser::GearStats::CONSUMABLE_EFFECT_KINDS

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
