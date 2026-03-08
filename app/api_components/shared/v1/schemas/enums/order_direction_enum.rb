# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class OrderDirectionEnum
          include Rswag::SchemaComponents::Component

          DIRECTIONS = %w[asc desc].freeze

          schema({
            type: :string,
            enum: DIRECTIONS,
            "x-enumNames": DIRECTIONS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
