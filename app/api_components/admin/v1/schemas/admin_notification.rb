# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminNotification
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            notificationType: ::Admin::V1::Schemas::Enums::AdminNotificationTypeEnum,
            severity: ::Admin::V1::Schemas::Enums::AdminNotificationSeverityEnum,
            title: {type: :string},
            body: {type: :string},
            link: {type: :string},
            icon: {type: :string},
            occurrences: {type: :integer},
            lastOccurredAt: {type: :string, format: "date-time"},
            read: {type: :boolean},
            readAt: {type: :string, format: "date-time"},
            archived: {type: :boolean},
            archivedAt: {type: :string, format: "date-time"},
            expiresAt: {type: :string, format: "date-time"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id notificationType severity title occurrences lastOccurredAt read archived expiresAt createdAt updatedAt]
        })
      end
    end
  end
end
