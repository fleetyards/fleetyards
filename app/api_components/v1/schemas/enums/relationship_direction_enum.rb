# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Which side of the relationship the reading party is on.
      class RelationshipDirectionEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[incoming outgoing].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
