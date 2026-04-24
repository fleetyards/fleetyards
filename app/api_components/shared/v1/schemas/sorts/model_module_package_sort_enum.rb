# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      module Sorts
        class ModelModulePackageSortEnum
          include Rswag::SchemaComponents::Component

          schema({
            type: :string,
            enum: ::ModelModulePackage::ALLOWED_SORTING_PARAMS,
            "x-enumNames": ::ModelModulePackage::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
          })
        end
      end
    end
  end
end
