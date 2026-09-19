# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Something in one of the reader's own inventories changed -- a hand-made
      # one or a ship's. The subscriber refetches, so the message carries no
      # stock: the page's unit of interest is a rolled-up position rather than
      # the entry that moved, and restating that aggregate here would mean
      # keeping a second copy of it in step with the endpoint's.
      #
      # It still names the inventory rather than being empty, so a page showing
      # one store can ignore a ping for another.
      class HangarInventoryChangedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            inventoryId: {type: :string, format: :uuid},
            inventorySlug: {type: :string}
          },
          additionalProperties: false,
          required: %w[inventoryId inventorySlug]
        })
      end
    end
  end
end
