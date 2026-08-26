# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContributionMonthlyStatsItem
        include OpenapiRuby::Components::Base

        schema({
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
        })
      end
    end
  end
end
