# frozen_string_literal: true

module V1
  module Schemas
    module Hangar
      module Logistics
        class HangarInventory
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              location: {type: :string},
              itemCount: {type: :integer},
              totalScu: {type: :number},
              totalUnits: {type: :number},
              totalVolumeScu: {type: :number},
              unmeasuredCount: {type: :integer},
              image: {"$ref": "#/components/schemas/MediaFile"},
              vehicle: {"$ref": "#/components/schemas/InventoryVehicle"},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug itemCount totalScu totalUnits createdAt updatedAt]
          })
        end
      end
    end
  end
end
