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
            quality: {type: :integer, minimum: 0, maximum: 1000, nullable: true},
            memberId: {type: :string, format: :uuid, nullable: true},
            image: {type: :string, nullable: true},
            notes: {type: :string, nullable: true},
            itemType: {type: :string, nullable: true},
            itemId: {type: :string, format: :uuid, nullable: true}
          },
          required: %w[name quantity],
          additionalProperties: false
        })
      end
    end
  end
end
