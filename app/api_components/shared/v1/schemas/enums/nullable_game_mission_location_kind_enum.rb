# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # See NullableInventoryItemTypeEnum for why nullable enums are their own
        # component instead of anyOf: [$ref, {type: :null}].
        class NullableGameMissionLocationKindEnum
          include OpenapiRuby::Components::Base

          VALUES = (GameMissionLocationKindEnum::VALUES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": GameMissionLocationKindEnum::VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
