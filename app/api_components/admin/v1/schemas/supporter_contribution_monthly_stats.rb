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
              items: SupporterContributionMonthlyStatsItem
            }
          },
          additionalProperties: false,
          required: %w[currency items]
        })
      end
    end
  end
end
