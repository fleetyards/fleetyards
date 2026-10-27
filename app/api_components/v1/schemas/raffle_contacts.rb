# frozen_string_literal: true

module V1
  module Schemas
    class RaffleContacts
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          discordHandle: {type: :string},
          discordInvite: {type: :string}
        },
        additionalProperties: false,
        required: %w[discordHandle discordInvite]
      })
    end
  end
end
