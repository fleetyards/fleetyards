# frozen_string_literal: true

module V1
  module Schemas
    class SupportGoalItem
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          title: {type: :string},
          description: {type: :string},
          amountCents: {type: :integer},
          currency: {type: :string}
        },
        additionalProperties: false,
        required: %w[title amountCents currency]
      })
    end
  end
end
