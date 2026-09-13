# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class InventoryTransferQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            stateEq: ::V1::Schemas::Enums::InventoryTransferStateEnum,
            stateIn: {
              type: :array,
              items: ::V1::Schemas::Enums::InventoryTransferStateEnum
            },
            createdAtGteq: {type: :string, format: "date-time"},
            createdAtLteq: {type: :string, format: "date-time"},
            s: ::V1::Schemas::Sorts::InventoryTransferSortEnum
          },
          additionalProperties: false
        })
      end
    end
  end
end
