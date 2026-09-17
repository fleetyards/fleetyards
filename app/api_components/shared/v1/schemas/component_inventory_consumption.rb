# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The space an item takes in an inventory, and how big it physically is.
      class ComponentInventoryConsumption
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            microScu: {type: :number},
            dimensions: {
              type: :object,
              properties: {
                x: {type: :number},
                y: {type: :number},
                z: {type: :number}
              },
              additionalProperties: false
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
