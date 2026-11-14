# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContributionDailyStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            currency: {type: :string},
            goalAmountCents: {type: :integer},
            items: {
              type: :array,
              items: SupporterContributionDailyStatsItem
            }
          },
          additionalProperties: false,
          required: %w[currency goalAmountCents items]
        })
      end
    end
  end
end
