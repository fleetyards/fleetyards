# frozen_string_literal: true

module V1
  module Schemas
    module Carts
      # One stop of the trip: a place and the lines bought there.
      class CartGroup
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string},
            name: {type: :string},
            # Null where a price names a place we could not match to one of ours.
            location: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
            systemName: {type: [:string, :null]},
            itemIds: {type: :array, items: {type: :string, format: :uuid}},
            subtotal: {type: :number}
          },
          additionalProperties: false,
          required: %w[key name itemIds subtotal]
        })
      end
    end
  end
end
