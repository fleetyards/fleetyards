# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMember
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            userId: {type: :string, format: :uuid},
            username: {type: :string},
            fleetRole: {"$ref": "#/components/schemas/FleetRole"},
            status: {"$ref": "#/components/schemas/FleetMembershipStatusEnum"},
            avatar: {"$ref": "#/components/schemas/MediaFile"},
            rsiHandle: {type: :string},
            homepage: {type: :string},
            discord: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            guilded: {type: :string},
            shipsFilter: {"$ref": "#/components/schemas/FleetMembershipShipsFilterEnum"},
            hangarGroupId: {type: :string, format: :uuid},
            fleetSlug: {type: :string},
            fleetName: {type: :string},
            fleet: {"$ref": "#/components/schemas/Fleet"},
            primary: {type: :boolean},
            verified: {type: :boolean},
            citizenidProfileUrl: {type: :string},
            discordProfileUrl: {type: :string},
            latitude: {type: :number, format: :double},
            longitude: {type: :number, format: :double},
            currentSystemCode: {type: :string},
            isDestroyAllowed: {type: :boolean},
            capabilities: {"$ref": "#/components/schemas/FleetMembershipCapabilities"},
            hangarUpdatedAt: {type: :string, format: "date-time"},
            lastActiveAt: {type: :string, format: "date-time"},
            invitedAt: {type: :string, format: "date-time"},
            invitedAtLabel: {type: :string},
            requestedAt: {type: :string, format: "date-time"},
            requestedAtLabel: {type: :string},
            acceptedAt: {type: :string, format: "date-time"},
            acceptedAtLabel: {type: :string},
            declinedAt: {type: :string, format: "date-time"},
            declinedAtLabel: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          # Not fleetRole: FleetRole cascades ahead of the memberships it
          # nullifies, so a membership torn down with its fleet is broadcast
          # without one.
          required: %w[id username shipsFilter fleetSlug fleetName createdAt updatedAt]
        })
      end
    end
  end
end
