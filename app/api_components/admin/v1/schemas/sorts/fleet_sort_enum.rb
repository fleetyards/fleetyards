# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Sorts
        class FleetSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Fleet::ADMIN_SORTING_PARAMS,
            "x-enumNames": ::Fleet::ADMIN_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
