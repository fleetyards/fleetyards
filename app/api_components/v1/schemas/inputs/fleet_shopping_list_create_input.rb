# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetShoppingListCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1, maxLength: 64},
            description: {type: [:string, :null], maxLength: 1000},
            visibility: ::V1::Schemas::Enums::FleetShoppingListVisibilityEnum,
            fleetSquadronIds: {type: :array, items: {type: :string, format: :uuid}},
            # The user's own list whose lines are published.
            cartId: {type: :string, format: :uuid}
          },
          required: %w[name cartId],
          additionalProperties: false
        })
      end
    end
  end
end
