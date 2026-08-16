# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminNotificationUnreadCount
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            count: {type: :integer}
          },
          additionalProperties: false,
          required: %w[count]
        })
      end
    end
  end
end
