# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Sorts
        class LocationSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Location::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::Location::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
