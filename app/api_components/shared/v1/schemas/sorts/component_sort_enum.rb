# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class ComponentSortEnum
          include OpenapiRuby::Components::Base

          schema({
            type: :string,
            enum: ::Component::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::Component::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
