# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryItemUpdateInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            notes: {type: :string, nullable: true},
            category: {type: :string, enum: %w[commodity component weapon equipment ammunition consumable other]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
