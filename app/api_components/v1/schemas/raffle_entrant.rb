# frozen_string_literal: true

module V1
  module Schemas
    class RaffleEntrant
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          username: {type: :string},
          enteredAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[username enteredAt]
      })
    end
  end
end
