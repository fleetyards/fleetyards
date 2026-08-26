# frozen_string_literal: true

module V1
  module Schemas
    class SupportMonthlyTotal
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          amountCents: {type: :integer},
          currency: {type: :string}
        },
        additionalProperties: false,
        required: %w[amountCents currency]
      })
    end
  end
end
