# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetInventoryVisibilityEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[members_only officers_only].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
