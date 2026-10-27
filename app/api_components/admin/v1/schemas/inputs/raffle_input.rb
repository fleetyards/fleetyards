# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class RaffleInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              title: {type: :string},
              description: {type: :string},
              modelId: {type: [:string, :null], format: :uuid},
              # Write-only: left out, the stored code stays as it is.
              code: {type: :string},
              startsAt: {type: :string, format: "date-time"},
              endsAt: {type: :string, format: "date-time"},
              claimPeriodDays: {type: :integer, minimum: 1},
              published: {type: :boolean}
            },
            additionalProperties: false,
            required: %w[title startsAt endsAt]
          })
        end
      end
    end
  end
end
