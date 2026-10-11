# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A member as a health check lists them: who they are and the facts the
      # checks are about, without the roster's links and locations.
      class FleetMemberHealthMember
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            nickname: {type: [:string, :null]},
            avatar: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]},
            fleetRole: {anyOf: [::V1::Schemas::Fleets::FleetRole, {type: :null}]},
            leader: {type: :boolean, description: "Holds a role ranked above the one new members get"},
            lastActiveAt: {type: [:string, :null], format: "date-time"},
            acceptedAt: {type: [:string, :null], format: "date-time"},
            requestedAt: {type: [:string, :null], format: "date-time"},
            invitedAt: {type: [:string, :null], format: "date-time"},
            invitedBy: {type: [:string, :null], description: "Username of whoever sent the invitation"},
            rsiHandle: {type: [:string, :null]},
            discordProfileUrl: {type: [:string, :null]},
            verificationGap: {
              anyOf: [::V1::Schemas::Enums::FleetMemberVerificationGapEnum, {type: :null}],
              description: "Why the member is not verified against the fleet's RSI org; null when they are"
            },
            rsiOrganizationsCheckedAt: {type: [:string, :null], format: "date-time"},
            verificationRemindedAt: {type: [:string, :null], format: "date-time", description: "When the fleet last reminded the member to verify"}
          },
          required: %w[id username leader verificationGap],
          additionalProperties: false
        })
      end
    end
  end
end
