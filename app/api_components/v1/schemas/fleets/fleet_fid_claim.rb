# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetFidClaim
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            state: ::Shared::V1::Schemas::Enums::FleetFidClaimStateEnum,
            cancelReason: ::Shared::V1::Schemas::Enums::NullableFleetFidClaimCancelReasonEnum,
            endsAt: {type: :string, format: "date-time"},
            claimantName: {type: :string},
            claimantFid: {type: :string},
            holderName: {type: [:string, :null]},
            holderFid: {type: [:string, :null]},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %i[id fid state cancelReason endsAt claimantName claimantFid holderName holderFid createdAt]
        })
      end
    end
  end
end
