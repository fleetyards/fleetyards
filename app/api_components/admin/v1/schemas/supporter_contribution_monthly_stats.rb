# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContributionMonthlyStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            currency: {type: :string},
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  label: {type: :string},
                  tooltip: {type: :string},
                  amountCents: {type: :integer},
                  goalAmountCents: {type: :integer},
                  count: {type: :integer}
                },
                additionalProperties: false,
                required: %w[label tooltip amountCents goalAmountCents count]
              }
            }
          },
          additionalProperties: false,
          required: %w[currency items]
        })
      end
    end
  end
end
