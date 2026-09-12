# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class TourStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[open settled cancelled].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
