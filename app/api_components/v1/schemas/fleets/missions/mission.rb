# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class Mission
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              title: {type: :string},
              slug: {type: :string},
              description: {type: :string},
              category: {"$ref": "#/components/schemas/MissionCategoryEnum"},
              scenario: {type: :string},
              coverImagePreset: {type: :string},
              coverImage: {"$ref": "#/components/schemas/MediaFile"},
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time"},
              createdBy: Shared::V1::Schemas::UserRef,
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
