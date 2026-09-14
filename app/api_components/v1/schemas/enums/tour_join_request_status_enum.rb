# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class TourJoinRequestStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[pending approved declined].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
