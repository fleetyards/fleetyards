# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # An activity an RSI organisation can name as its primary or secondary focus.
      class FleetActivityEnum
        include OpenapiRuby::Components::Base

        VALUES = ::Fleet::ACTIVITIES

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
