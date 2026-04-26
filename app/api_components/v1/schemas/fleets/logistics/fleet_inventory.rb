# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventory
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              description: {type: :string, nullable: true},
              visibility: {type: :string, enum: %w[members_only officers_only]},
              location: {type: :string, nullable: true},
              itemCount: {type: :integer},
              totalScu: {type: :number},
              totalUnits: {type: :number},
              manager: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              image: {"$ref": "#/components/schemas/MediaFile"},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            additionalProperties: false,
            required: %w[id name slug visibility itemCount totalScu totalUnits createdAt updatedAt]
          })
        end
      end
    end
  end
end
