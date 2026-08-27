# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Sorts
        class EquipmentSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Equipment::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::Equipment::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
