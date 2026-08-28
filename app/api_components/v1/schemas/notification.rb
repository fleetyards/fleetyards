# frozen_string_literal: true

module V1
  module Schemas
    class Notification
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          notificationType: ::V1::Schemas::Enums::NotificationTypeEnum,
          title: {type: :string},
          body: {type: :string},
          link: {type: :string},
          icon: {type: :string},
          record: ::V1::Schemas::NotificationRecord,
          read: {type: :boolean},
          readAt: {type: :string, format: "date-time"},
          archived: {type: :boolean},
          archivedAt: {type: :string, format: "date-time"},
          deletesAt: {type: :string, format: "date-time"},
          expiresAt: {type: :string, format: "date-time"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id notificationType title read archived expiresAt createdAt updatedAt]
      })
    end
  end
end
