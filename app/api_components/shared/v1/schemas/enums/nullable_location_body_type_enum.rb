# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What kind of world a planet or moon is, where that changes how it is
        # drawn. Null for an ordinary rocky or icy body.
        #
        # Nullable enums get a component of their own rather than
        # anyOf: [$ref, {type: :null}] — see NullableInventoryItemTypeEnum.
        class NullableLocationBodyTypeEnum
          include OpenapiRuby::Components::Base

          VALUES = (::ScData::Parser::StarmapParser::BODY_TYPE_VALUES + [nil]).freeze

          schema({
            type: [:string, :null],
            enum: VALUES,
            "x-enumNames": ::ScData::Parser::StarmapParser::BODY_TYPE_VALUES.map { |value| transform_enum_key(value) } + ["NULL"]
          })
        end
      end
    end
  end
end
