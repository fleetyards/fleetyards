# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetRsiVerification
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            sid: {type: [:string, :null]},
            token: {type: [:string, :null]},
            status: ::V1::Schemas::Enums::NullableFleetRsiVerificationStatusEnum,
            verified: {type: :boolean},
            verifiedAt: {type: [:string, :null], format: "date-time"},
            checkedAt: {type: [:string, :null], format: "date-time"},
            # Only present while a new check would not reach RSI.
            nextCheckAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %i[sid token status verified verifiedAt checkedAt]
        })
      end
    end
  end
end
