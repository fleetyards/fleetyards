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
              category: ::V1::Schemas::Enums::MissionCategoryEnum,
              scenario: {type: :string},
              coverImagePreset: {type: :string},
              coverImage: ::Shared::V1::Schemas::MediaFile,
              archived: {type: :boolean},
              archivedAt: {type: :string, format: "date-time"},
              createdBy: ::V1::Schemas::UserRef,
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
