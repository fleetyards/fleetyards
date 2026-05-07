# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class VehicleSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: Vehicle::ALLOWED_SORTING_PARAMS,
            "x-enumNames": Vehicle::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
