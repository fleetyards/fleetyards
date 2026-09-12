# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class Tour
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            title: {type: :string},
            slug: {type: :string},
            description: {type: [:string, :null]},
            status: ::V1::Schemas::Enums::TourStatusEnum,
            startsAt: {type: [:string, :null], format: "date-time"},
            settledAt: {type: [:string, :null], format: "date-time"},
            createdBy: ::V1::Schemas::UserRef,
            # Only ever present for the organiser; it is the credential the
            # invite link carries.
            inviteToken: {type: [:string, :null]},
            payoutLedgerId: {type: [:string, :null], format: :uuid},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id title slug status],
          additionalProperties: false
        })
      end
    end
  end
end
