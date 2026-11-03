# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # How a fire mode shoots: a held trigger, one shot, a burst, a charged shot or a beam.
        class EquipmentFireModeKindEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ScData::Parser::GearStats::FIRE_MODE_KINDS

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
