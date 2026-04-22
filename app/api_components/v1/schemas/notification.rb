# frozen_string_literal: true

module V1
  module Schemas
    class Notification
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          notificationType: {"$ref": "#/components/schemas/NotificationTypeEnum"},
          title: {type: :string},
          body: {type: :string, nullable: true},
          link: {type: :string, nullable: true},
          icon: {type: :string, nullable: true},
          read: {type: :boolean},
          readAt: {type: :string, format: "date-time", nullable: true},
          expiresAt: {type: :string, format: "date-time"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id notificationType title read expiresAt createdAt updatedAt]
      })
    end
  end
end
