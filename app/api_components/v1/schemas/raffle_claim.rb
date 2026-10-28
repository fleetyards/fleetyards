# frozen_string_literal: true

module V1
  module Schemas
    class RaffleClaim
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          raffleId: {type: :string, format: :uuid},
          raffleTitle: {type: :string},
          claimedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[raffleId raffleTitle claimedAt]
      })
    end
  end
end
