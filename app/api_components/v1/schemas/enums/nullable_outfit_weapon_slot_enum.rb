# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class NullableOutfitWeaponSlotEnum
        include OpenapiRuby::Components::Base

        VALUES = (OutfitWeaponSlotEnum::VALUES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": OutfitWeaponSlotEnum::VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
