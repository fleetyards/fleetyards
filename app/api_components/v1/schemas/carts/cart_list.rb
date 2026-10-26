# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      class CartList
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            # The list items added from the catalogues go to.
            active: {type: :boolean},
            itemsCount: {type: :integer},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name active itemsCount createdAt updatedAt]
        })
      end
    end
  end
end
