# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class Mission
          include Rswag::SchemaComponents::Component

          CATEGORIES = %w[
            other
            ship_combat
            ground_combat
            combined_combat
            mining
            salvage
            cargo_hauling
            exploration
          ].freeze

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              title: {type: :string},
              slug: {type: :string},
              description: {type: :string, nullable: true},
              category: {type: :string, enum: CATEGORIES},
              scenario: {type: :string, nullable: true},
              coverImage: {"$ref": "#/components/schemas/MediaFile", nullable: true},
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time", nullable: true},
              createdBy: {
                type: :object,
                nullable: true,
                properties: {
                  id: {type: :string, format: :uuid},
                  username: {type: :string}
                }
              },
              teamCount: {type: :integer},
              shipCount: {type: :integer},
              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"}
            },
            required: %w[id title slug category archived teamCount shipCount createdAt updatedAt]
          })
        end
      end
    end
  end
end
