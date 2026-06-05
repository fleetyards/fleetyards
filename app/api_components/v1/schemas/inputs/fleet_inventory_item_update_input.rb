# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetInventoryItemUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            notes: {type: [:string, :null]},
            category: {type: :string, enum: %w[commodity component weapon equipment ammunition consumable other]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
