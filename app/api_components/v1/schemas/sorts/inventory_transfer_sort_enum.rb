# frozen_string_literal: true

module V1
  module Schemas
    module Sorts
      class InventoryTransferSortEnum
        include OpenapiRuby::Components::Base

        schema({
          type: :string,
          enum: ::InventoryTransfer::ALLOWED_SORTING_PARAMS,
          "x-enumNames": ::InventoryTransfer::ALLOWED_SORTING_PARAMS.map { |v| transform_enum_key(v) }
        })
      end
    end
  end
end
