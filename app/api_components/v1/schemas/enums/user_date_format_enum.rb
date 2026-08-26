# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class UserDateFormatEnum
        include OpenapiRuby::Components::Base

        VALUES = ::User::DATE_FORMATS.keys.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
