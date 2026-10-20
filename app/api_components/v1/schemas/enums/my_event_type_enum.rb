# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class MyEventTypeEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[fleet_event game_event].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
