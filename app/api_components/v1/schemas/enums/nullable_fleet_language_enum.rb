# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Nullable enums get a component of their own rather than
      # anyOf: [$ref, {type: :null}].
      class NullableFleetLanguageEnum
        include OpenapiRuby::Components::Base

        VALUES = (::Rsi::Languages::CODES + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::Rsi::Languages::CODES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
