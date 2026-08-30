# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Inventory
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            holderId: {type: :string, format: :uuid},
            holderType: {type: :string},
            name: {type: :string},
            slug: {type: :string},
            description: {type: [:string, :null]},
            location: {type: [:string, :null]},
            # A ship provisions its own; the rest were made by hand.
            vehicleId: {type: [:string, :null], format: :uuid},
            itemsCount: {type: :integer},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id holderId holderType name slug itemsCount createdAt updatedAt]
        })
      end
    end
  end
end
