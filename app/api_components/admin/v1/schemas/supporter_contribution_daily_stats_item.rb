# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContributionDailyStatsItem
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            label: {type: :string},
            current: {type: :boolean},
            days: {
              type: :array,
              items: {type: :integer},
              description: "Running total in cents at the end of each day of the month, from the 1st. The current month stops at today."
            }
          },
          additionalProperties: false,
          required: %w[label current days]
        })
      end
    end
  end
end
