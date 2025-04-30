# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class FleetMember
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            fleetRole: {"$ref": "#/components/schemas/FleetRole"},
            status: {"$ref": "#/components/schemas/FleetMembershipStatusEnum"},
            avatar: {type: :string},
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
            hangarUpdatedAt: {type: :string, format: "date-time"},
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
          required: %w[id username fleetRole shipsFilter fleetSlug fleetName createdAt updatedAt]
        })
      end
    end
  end
end
