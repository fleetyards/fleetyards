# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FundingGoal
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            description: {type: :string},
            amountCents: {type: :integer},
            currency: {type: :string},
            effectiveFrom: {type: :string, format: :date},
            endedAt: {type: :string, format: :date},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title amountCents currency effectiveFrom createdAt updatedAt]
        })
      end
    end
  end
end
