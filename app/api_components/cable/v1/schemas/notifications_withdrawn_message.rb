# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Notifications deleted because what they were about was taken down, so
      # an open inbox and its badge can drop them without a reload.
      class NotificationsWithdrawnMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            withdrawnIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false,
          required: %w[withdrawnIds]
        })
      end
    end
  end
end
