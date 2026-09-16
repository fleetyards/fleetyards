# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Announcement
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            body: {type: :string},
            discordParts: {type: :array, items: {type: :string}},
            socialParts: {type: :array, items: {type: :string}},
            link: {type: :string},
            icon: {type: :string},
            status: ::Admin::V1::Schemas::Enums::AnnouncementStatusEnum,
            publishAt: {type: :string, format: "date-time"},
            publishedAt: {type: :string, format: "date-time"},
            recipientsCount: {type: :integer},
            notifyUsers: {type: :boolean},
            postDiscord: {type: :boolean},
            postBluesky: {type: :boolean},
            postX: {type: :boolean},
            publishable: {type: :boolean},
            lastTestedAt: {type: :string, format: "date-time"},
            author: {type: :string},
            deliveries: {type: :array, items: ::Admin::V1::Schemas::AnnouncementDelivery},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id title body icon status notifyUsers postDiscord postBluesky postX
            publishable deliveries discordParts socialParts createdAt updatedAt
          ]
        })
      end
    end
  end
end
