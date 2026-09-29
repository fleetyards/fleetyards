# frozen_string_literal: true

module V1
  module Schemas
    class UserRsiVerification
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          handle: {type: [:string, :null]},
          token: {type: [:string, :null]},
          status: ::V1::Schemas::Enums::NullableUserRsiVerificationStatusEnum,
          verified: {type: :boolean},
          verifiedVia: ::V1::Schemas::Enums::NullableRsiHandleVerifiedViaEnum,
          verifiedAt: {type: [:string, :null], format: "date-time"},
          checkedAt: {type: [:string, :null], format: "date-time"},
          # Only present while a new check would not reach RSI.
          nextCheckAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %i[handle token status verified verifiedVia verifiedAt checkedAt]
      })
    end
  end
end
