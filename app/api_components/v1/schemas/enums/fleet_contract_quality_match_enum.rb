# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # How a line's grade is read: at or above it, or exactly it.
      class FleetContractQualityMatchEnum
        include OpenapiRuby::Components::Base

        VALUES = ::FleetContractItem::QUALITY_MATCHES.keys.map(&:to_s).freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
