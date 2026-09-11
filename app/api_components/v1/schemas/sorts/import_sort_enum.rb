# frozen_string_literal: true

module V1
  module Schemas
    module Sorts
      class ImportSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::Import::ALLOWED_SORTING_PARAMS,
          "x-enumNames": ::Import::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
