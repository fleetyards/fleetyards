# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # Whether a place is an armistice zone as a whole or only in parts.
        # Null where it has none.
        #
        # Nullable enums get a component of their own rather than
        # anyOf: [$ref, {type: :null}] — see NullableInventoryItemTypeEnum.
        class NullableLocationArmisticeEnum
          include OpenapiRuby::Components::Base

          VALUES = (::ScData::Parser::StarmapParser::ARMISTICE_VALUES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::ScData::Parser::StarmapParser::ARMISTICE_VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
