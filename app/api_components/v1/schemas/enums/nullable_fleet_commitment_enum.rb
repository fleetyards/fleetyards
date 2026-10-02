# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Nullable enums get a component of their own rather than
      # anyOf: [$ref, {type: :null}].
      class NullableFleetCommitmentEnum
        include OpenapiRuby::Components::Base

        VALUES = (::Fleet::COMMITMENTS + [nil]).freeze

        schema({
          type: [:string, :null],
          enum: VALUES,
          "x-enumNames": ::Fleet::COMMITMENTS.map { |value| transform_enum_key(value) } + ["NULL"]
        })
      end
    end
  end
end
