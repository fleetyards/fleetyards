# frozen_string_literal: true

module Admin
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
            category: ::Admin::V1::Schemas::Enums::GameEventCategoryEnum,
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: :string, format: "date-time"},
            published: {type: :boolean},
            coverImage: ::Shared::V1::Schemas::MediaFile,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title category startsAt published createdAt updatedAt]
        })
      end
    end
  end
end
