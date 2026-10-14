# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Enums
        class VehicleImageSourceFilterEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: Vehicle::IMAGE_SOURCE_FILTERS,
            "x-enumNames": Vehicle::IMAGE_SOURCE_FILTERS.map { |value| transform_enum_key(value) }
          })
        end
      end
    end
  end
end
