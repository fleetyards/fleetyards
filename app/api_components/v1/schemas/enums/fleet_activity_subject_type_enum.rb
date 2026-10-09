# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetActivitySubjectTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[member event contract inventory_transfer inventory_item].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
