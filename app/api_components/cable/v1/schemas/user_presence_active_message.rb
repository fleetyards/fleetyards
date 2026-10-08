# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # A client reporting that one of its tabs is in front of the user, which
      # holds push notifications back on all of their devices.
      class UserPresenceActiveMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            action: {type: :string, enum: %w[active]}
          },
          additionalProperties: false,
          required: %w[action]
        })
      end
    end
  end
end
