# frozen_string_literal: true

module V1
  module Schemas
    class NotificationBulkResult
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
