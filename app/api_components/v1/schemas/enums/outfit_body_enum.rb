# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class OutfitBodyEnum
        include OpenapiRuby::Components::Base

        VALUES = ::ItemViews::RIGGED_BODIES

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
