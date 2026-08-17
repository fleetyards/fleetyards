# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class InventoryItemUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            notes: {type: [:string, :null]},
            category: {type: :string, enum: %w[commodity component weapon equipment ammunition consumable other]},
            unit: {type: :string, enum: %w[scu units]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
