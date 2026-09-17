# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class SupporterContributionInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              amountCents: {type: :integer},
              currency: {type: :string},
              anonymous: {type: :boolean},
              recurring: {type: :boolean},
              source: ::Admin::V1::Schemas::Enums::NullableSupporterContributionSourceEnum,
              startedAt: {type: :string, format: :date},
              endedAt: {type: :string, format: :date},
              note: {type: :string},
              payerEmail: {type: [:string, :null]},
              claimKey: {type: [:string, :null]},
              userId: {type: [:string, :null], format: :uuid}
            },
            additionalProperties: false,
            required: %w[amountCents startedAt]
          })
        end
      end
    end
  end
end
