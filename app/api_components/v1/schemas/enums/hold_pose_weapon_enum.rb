# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class HoldPoseWeaponEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::CharacterBody::HOLD_WEAPONS,
          "x-enumNames": ::CharacterBody::HOLD_WEAPONS.map { |weapon| transform_enum_key(weapon) }
        })
      end
    end
  end
end
