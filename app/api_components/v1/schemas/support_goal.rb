# frozen_string_literal: true

module V1
  module Schemas
    class SupportGoal
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          amountCents: {type: :integer},
          currency: {type: :string},
          items: {
            type: :array,
            items: SupportGoalItem
          }
        },
        additionalProperties: false,
        required: %w[amountCents currency items]
      })
    end
  end
end
