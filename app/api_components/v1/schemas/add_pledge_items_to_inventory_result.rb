# frozen_string_literal: true

module V1
  module Schemas
    class AddPledgeItemsToInventoryResult
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          addedPledgeItemIds: {type: :array, items: {type: :string, format: :uuid}},
          skippedPledgeItemIds: {
            type: :array,
            items: {type: :string, format: :uuid},
            description: "Items already in an inventory, left as they were"
          }
        },
        additionalProperties: false,
        required: %w[addedPledgeItemIds skippedPledgeItemIds]
      })
    end
  end
end
