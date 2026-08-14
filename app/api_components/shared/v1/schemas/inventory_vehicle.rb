# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # Where an inventory is, as far as an inventory needs to know. Null for
      # inventories a user keeps somewhere other than a ship.
      class InventoryVehicle
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            serial: {type: [:string, :null]},
            model: {
              type: :object,
              properties: {
                name: {type: :string},
                slug: {type: :string},
                cargo: {type: :number}
              }
            }
          },
          additionalProperties: false,
          required: %w[id name]
        })
      end
    end
  end
end
