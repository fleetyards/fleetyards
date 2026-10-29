# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Only the id: the raffle itself depends on who reads it and in which
      # language, so the client refetches it rather than taking it from here.
      class RaffleChangedMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            raffleId: {type: :string, format: :uuid}
          },
          additionalProperties: false,
          required: %w[raffleId]
        })
      end
    end
  end
end
