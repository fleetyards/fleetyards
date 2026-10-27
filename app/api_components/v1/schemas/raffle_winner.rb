# frozen_string_literal: true

module V1
  module Schemas
    class RaffleWinner
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          username: {type: :string},
          drawPosition: {type: :integer},
          wonAt: {type: :string, format: "date-time"},
          claimDeadlineAt: {type: :string, format: "date-time"},
          claimedAt: {type: :string, format: "date-time"},
          forfeitedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[username drawPosition wonAt claimDeadlineAt]
      })
    end
  end
end
