# frozen_string_literal: true

module V1
  module Schemas
    class NotificationPreference
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          notificationType: ::V1::Schemas::Enums::NotificationTypeEnum,
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
