# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventory
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              visibility: {"$ref": "#/components/schemas/FleetInventoryVisibilityEnum"},
              location: {type: :string},
              entriesCount: {type: :integer},
              totalScu: {type: :number},
              totalUnits: {type: :number},
              manager: FleetInventoryManager,
              image: {"$ref": "#/components/schemas/MediaFile"},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug visibility entriesCount totalScu totalUnits createdAt updatedAt]
          })
        end
      end
    end
  end
end
