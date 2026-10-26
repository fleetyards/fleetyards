# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetShoppingListUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1, maxLength: 64},
            description: {type: [:string, :null], maxLength: 1000},
            visibility: ::V1::Schemas::Enums::FleetShoppingListVisibilityEnum,
            fleetSquadronIds: {type: :array, items: {type: :string, format: :uuid}},
            # Replaces every line with this list's.
            cartId: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
