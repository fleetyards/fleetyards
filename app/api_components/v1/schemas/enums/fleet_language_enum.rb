# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # The ISO 639-1 code of an RSI organisation's primary language, from RSI's own list.
      class FleetLanguageEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Rsi::Languages::CODES

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
