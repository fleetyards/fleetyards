# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      class FleetEventStatusEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[draft open locked active completed cancelled].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
