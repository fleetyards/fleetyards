# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class ManufacturerSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Manufacturer::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::Manufacturer::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
