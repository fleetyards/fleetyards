# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Enums
        class ModelHullPartCategoryEnum
          include OpenapiRuby::Components::Base

          VALUES = %w[vital secondary breakable subpart cosmetic].freeze

          schema({
            type: :string,
            enum: VALUES,
            "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
