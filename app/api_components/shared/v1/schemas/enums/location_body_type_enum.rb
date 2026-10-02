# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        # What kind of world a planet or moon is, where that changes how it is
        # drawn. Null for an ordinary rocky or icy body.
        class LocationBodyTypeEnum
          include OpenapiRuby::Components::Base

          VALUES = ::ScData::Parser::StarmapParser::BODY_TYPE_VALUES

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
