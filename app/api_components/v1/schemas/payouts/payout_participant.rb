# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutParticipant
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            payoutLedgerId: {type: :string, format: :uuid},
            displayName: {type: :string},
            guest: {type: :boolean},
            user: ::V1::Schemas::UserRef,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id payoutLedgerId displayName guest],
          additionalProperties: false
        })
      end
    end
  end
end
