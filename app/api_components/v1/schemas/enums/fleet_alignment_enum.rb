# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Which side of the law a fleet says it plays on. Fleetyards' own field: RSI has none.
      class FleetAlignmentEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Fleet::ALIGNMENTS

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
