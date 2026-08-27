# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class InventoryVehicleModel
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string},
            cargo: {type: :number},
            personalInventory: {type: :number}
          }
        })
      end
    end
  end
end
