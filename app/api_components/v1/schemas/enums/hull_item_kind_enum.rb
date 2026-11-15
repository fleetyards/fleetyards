# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # What a built-in item left in the hull holo is. An export naming a kind
      # not listed here is served as `other`.
      class HullItemKindEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[weapon turret missile thruster utility other].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
