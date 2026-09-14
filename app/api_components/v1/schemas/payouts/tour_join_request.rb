# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class TourJoinRequest
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            tourId: {type: :string, format: :uuid},
            status: ::V1::Schemas::Enums::TourJoinRequestStatusEnum,
            user: ::V1::Schemas::UserRefWithAvatar,
            # Only once somebody has answered; a pending request omits the key
            # rather than sending a null object.
            decidedBy: ::V1::Schemas::UserRef,
            decidedAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id tourId status user],
          additionalProperties: false
        })
      end
    end
  end
end
