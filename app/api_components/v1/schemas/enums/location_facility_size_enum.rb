# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # The sizes a ship is sold in, as far as the game sizes its pads: there is
      # no capital pad.
      class LocationFacilitySizeEnum
        include OpenapiRuby::Components::Base

        VALUES = ::ScData::Parser::StarmapParser::PAD_SIZES.values.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
