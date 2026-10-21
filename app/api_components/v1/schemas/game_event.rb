# frozen_string_literal: true

module V1
  module Schemas
    class GameEvent
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          title: {type: :string},
          description: {type: :string},
          location: {type: :string},
          url: {type: :string},
          category: ::V1::Schemas::Enums::MissionCategoryEnum,
          startsAt: {type: :string, format: "date-time"},
          endsAt: {type: :string, format: "date-time"},
          coverImage: ::Shared::V1::Schemas::MediaFile,
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id title category startsAt createdAt updatedAt]
      })
    end
  end
end
