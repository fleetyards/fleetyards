# frozen_string_literal: true

module V1
  module Schemas
    module Transfers
      class InventoryTransfersList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: ::V1::Schemas::Transfers::InventoryTransfer
            },
            meta: ::Shared::V1::Schemas::Meta
          },
          required: %w[items meta]
        })
      end
    end
  end
end
