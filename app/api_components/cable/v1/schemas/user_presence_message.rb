# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # One user came online or went offline.
      #
      # Two fields and an id rather than a rendered member: the reader already
      # holds the row, and a user in ten fleets reaches up to 702 co-members, so
      # the message has to stay cheap enough to send that many times.
      #
      # `lastActiveAt` rides along because it is what a roster falls back to
      # once the dot goes grey, and the transition is the moment it changes.
      class UserPresenceMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            userId: {type: :string, format: :uuid},
            online: {type: :boolean},
            lastActiveAt: {type: [:string, :null], format: "date-time"}
          },
          additionalProperties: false,
          required: %w[userId online]
        })
      end
    end
  end
end
