# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Null for a type RSI's map has that the import does not know yet.
      class NullableStarSystemTypeEnum
        include OpenapiRuby::Components::Base

        schema({
          type: [:string, :null],
          enum: ::StarSystem::TYPES + [nil],
          "x-enumNames": ::StarSystem::TYPES.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
