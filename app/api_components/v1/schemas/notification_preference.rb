# frozen_string_literal: true

module V1
  module Schemas
    class NotificationPreference
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          notificationType: {"$ref": "#/components/schemas/NotificationTypeEnum"},
          app: {type: :boolean},
          mail: {type: :boolean},
          push: {type: :boolean},
          mailAvailable: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[notificationType app mail push mailAvailable]
      })
    end
  end
end
