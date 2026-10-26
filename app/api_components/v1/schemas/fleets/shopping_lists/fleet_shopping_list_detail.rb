# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module ShoppingLists
        class FleetShoppingListDetail
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              description: {type: [:string, :null]},
              visibility: ::V1::Schemas::Enums::FleetShoppingListVisibilityEnum,
              fleetSquadrons: {
                type: :array,
                items: ::V1::Schemas::Fleets::Squadrons::FleetSquadronRef
              },
              # How many different items it lists.
              linesCount: {type: :integer},
              # What its lines add up to: four of one item count four.
              itemsCount: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"},
              # Each line at its cheapest place, as a cart prices it.
              items: {type: :array, items: ::V1::Schemas::Carts::CartLine},
              totals: ::V1::Schemas::Carts::CartTotals
            },
            additionalProperties: false,
            required: %w[id name description visibility fleetSquadrons linesCount itemsCount createdAt updatedAt items totals]
          })
        end
      end
    end
  end
end
