# frozen_string_literal: true

module V1
  module Schemas
    module Enums
      # Tri-state filter: absent means "exclude ships the owner hid", true adds
      # them alongside the rest, only narrows to them.
      class HiddenVehiclesFilterEnum
        include OpenapiRuby::Components::Base

        VALUES = %w[true only].freeze

        schema({
          type: :string,
          enum: VALUES,
          "x-enumNames": VALUES.map { |value| transform_enum_key(value) }
        })
      end
    end
  end
end
