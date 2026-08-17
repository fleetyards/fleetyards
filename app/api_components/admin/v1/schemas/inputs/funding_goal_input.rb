# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FundingGoalInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              title: {type: :string},
              description: {type: :string},
              amountCents: {type: :integer},
              currency: {type: :string},
              effectiveFrom: {type: :string, format: :date},
              endedAt: {type: :string, format: :date}
            },
            additionalProperties: false,
            required: %w[title amountCents effectiveFrom]
          })
        end
      end
    end
  end
end
