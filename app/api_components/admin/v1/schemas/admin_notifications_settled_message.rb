# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      # Notifications that were read, archived or deleted, so every open admin
      # tab can take down the toasts that still announce them.
      class AdminNotificationsSettledMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            settledIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false,
          required: %w[settledIds]
        })
      end
    end
  end
end
