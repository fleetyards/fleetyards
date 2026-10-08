# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # A client reporting whether one of its tabs is in use, which holds push
      # notifications back on all of the user's devices while it is.
      class UserPresenceActivityMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            action: {type: :string, enum: %w[active inactive]}
          },
          additionalProperties: false,
          required: %w[action]
        })
      end
    end
  end
end
