# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetFidClaimStatus
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            availability: ::V1::Schemas::Enums::FleetFidClaimAvailabilityEnum,
            # The FID this fleet may claim: its verified SID, or null.
            fid: {type: [:string, :null]},
            # The fleet's own open claim, when it has one.
            outgoing: ::V1::Schemas::Fleets::FleetFidClaim,
            # An open claim on the FID this fleet holds, when there is one.
            incoming: ::V1::Schemas::Fleets::FleetFidClaim
          },
          additionalProperties: false,
          required: %i[availability fid]
        })
      end
    end
  end
end
