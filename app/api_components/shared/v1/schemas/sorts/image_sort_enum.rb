# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class ImageSortEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::Image::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::Image::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
