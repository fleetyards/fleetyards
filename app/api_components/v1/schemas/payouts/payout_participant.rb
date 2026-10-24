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
            # Pays the reward rather than sharing in it: the fleet, or the author
            # of a personal contract.
            payer: {type: :boolean},
            # What this participant is entitled to relative to the others.
            # A decimal like every other, so it is carried as a string.
            weight: {type: :string},
            user: ::V1::Schemas::UserRefWithAvatar,
            fleet: ::V1::Schemas::FleetRef,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id payoutLedgerId displayName guest payer weight],
          additionalProperties: false
        })
      end
    end
  end
end
