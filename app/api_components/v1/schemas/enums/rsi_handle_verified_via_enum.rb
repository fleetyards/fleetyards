# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class RsiHandleVerifiedViaEnum
        include OpenapiRuby::Components::Base

        VALUES = ::User.defined_enums.fetch("rsi_handle_verified_via").keys.freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
