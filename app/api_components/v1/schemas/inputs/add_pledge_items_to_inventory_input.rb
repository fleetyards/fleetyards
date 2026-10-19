# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class AddPledgeItemsToInventoryInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            pledgeItemIds: {
              type: :array,
              items: {type: :string, format: :uuid},
              description: "Ship components and FPS gear to add; any other pledge item is ignored"
            }
          },
          additionalProperties: false,
          required: %w[pledgeItemIds]
        })
      end
    end
  end
end
