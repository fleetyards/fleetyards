# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      class CartLine
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            quantity: {type: :integer},
            item: ::V1::Schemas::InventoryItemRef,
            # False when no shop sells the item; it is then left out of the total.
            available: {type: :boolean},
            # Whether the user chose the place, rather than the cheapest one.
            pinned: {type: :boolean},
            unitPrice: {type: [:number, :null]},
            total: {type: [:number, :null]},
            price: {anyOf: [::V1::Schemas::ItemPrice, {type: :null}]},
            # One price per place selling the item, cheapest first.
            offers: {type: :array, items: ::V1::Schemas::ItemPrice},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id quantity item available pinned offers createdAt updatedAt]
        })
      end
    end
  end
end
