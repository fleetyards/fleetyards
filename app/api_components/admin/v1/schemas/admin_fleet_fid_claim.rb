# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class AdminFleetFidClaim
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            state: ::Shared::V1::Schemas::Enums::FleetFidClaimStateEnum,
            cancelReason: ::Shared::V1::Schemas::Enums::NullableFleetFidClaimCancelReasonEnum,
            endsAt: {type: :string, format: "date-time"},
            claimantId: {type: :string, format: :uuid},
            claimantName: {type: :string},
            claimantFid: {type: :string},
            holderId: {type: [:string, :null], format: :uuid},
            holderName: {type: [:string, :null]},
            holderFid: {type: [:string, :null]},
            holderNewFid: {type: [:string, :null]},
            completedAt: {type: [:string, :null], format: "date-time"},
            cancelledAt: {type: [:string, :null], format: "date-time"},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %i[
            id fid state cancelReason endsAt claimantId claimantName claimantFid
            holderId holderName holderFid holderNewFid completedAt cancelledAt createdAt
          ]
        })
      end
    end
  end
end
