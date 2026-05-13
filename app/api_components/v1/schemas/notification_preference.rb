# frozen_string_literal: true

module V1
  module Schemas
    class NotificationPreference
      include Rswag::SchemaComponents::Component

      schema({
        type: :object,
        properties: {
          notificationType: {"$ref": "#/components/schemas/NotificationTypeEnum"},
          app: {type: :boolean},
          mail: {type: :boolean},
          push: {type: :boolean},
          mailAvailable: {type: :boolean},
          pushAvailable: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[notificationType app mail push mailAvailable pushAvailable]
      })
    end
  end
end
