# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryItemCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            category: {type: :string, enum: %w[commodity component weapon equipment ammunition consumable other]},
            quantity: {type: :number},
            unit: {type: :string, enum: %w[scu units]},
            entryType: {type: :string, enum: %w[deposit withdrawal]},
            quality: {type: [:integer, :null], minimum: 0, maximum: 1000},
            memberId: {type: [:string, :null], format: :uuid},
            image: {type: [:string, :null]},
            notes: {type: [:string, :null]},
            itemType: {type: [:string, :null]},
            itemId: {type: [:string, :null], format: :uuid}
          },
          required: %w[name quantity],
          additionalProperties: false
        })
      end
    end
  end
end
