# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class SupporterContribution
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            amountCents: {type: :integer},
            currency: {type: :string},
            anonymous: {type: :boolean},
            recurring: {type: :boolean},
            source: {"$ref": "#/components/schemas/SupporterContributionSourceEnum"},
            patreonMemberId: {type: :string},
            startedAt: {type: :string, format: :date},
            endedAt: {type: :string, format: :date},
            note: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id amountCents currency anonymous recurring source startedAt createdAt updatedAt]
        })
      end
    end
  end
end
