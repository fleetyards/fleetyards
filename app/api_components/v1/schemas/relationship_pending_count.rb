# frozen_string_literal: true

module V1
  module Schemas
    # How many requests are waiting on the reader. Shaped like
    # `NotificationUnreadCount` rather than reusing it: the same two fields say
    # different things, and a shared component would tie a friendship's payload
    # to a notification's.
    class RelationshipPendingCount
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
