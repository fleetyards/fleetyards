# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module ShoppingLists
        class FleetShoppingListsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Fleets::ShoppingLists::FleetShoppingList
          })
        end
      end
    end
  end
end
