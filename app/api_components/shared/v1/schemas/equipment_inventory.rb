# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class EquipmentInventory
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "What a worn piece can hold: its capacity in microSCU, and the interior an item has to fit inside, in metres",
          properties: {
            capacity: {type: :integer},
            dimensions: ::Shared::V1::Schemas::EquipmentInventoryDimensions
          },
          additionalProperties: false,
          required: %w[capacity dimensions]
        })
      end
    end
  end
end
