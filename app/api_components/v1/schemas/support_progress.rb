# frozen_string_literal: true

module V1
  module Schemas
    class SupportProgress
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          goal: SupportGoal,
          monthlyTotal: SupportMonthlyTotal,
          contributions: {
            type: :array,
            items: SupportContribution
          }
        },
        additionalProperties: false,
        required: %w[monthlyTotal contributions]
      })
    end
  end
end
