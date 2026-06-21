# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContributionStats
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalAmountCents: {type: :integer},
            currency: {type: :string},
            totalCount: {type: :integer},
            recurringCount: {type: :integer},
            anonymousCount: {type: :integer}
          },
          additionalProperties: false,
          required: %w[totalAmountCents currency totalCount recurringCount anonymousCount]
        })
      end
    end
  end
end
