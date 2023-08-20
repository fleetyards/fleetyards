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
            role: {"$ref": "#/components/schemas/FleetMembershipRoleEnum"},
            roleLabel: {type: :string},
            status: {"$ref": "#/components/schemas/FleetMembershipStatusEnum"},
            avatar: {type: :string, nullable: true},
            rsiHandle: {type: :string, nullable: true},
            homepage: {type: :string, nullable: true},
            discord: {type: :string, nullable: true},
            youtube: {type: :string, nullable: true},
            twitch: {type: :string, nullable: true},
            guilded: {type: :string, nullable: true},
            shipsFilter: {"$ref": "#/components/schemas/FleetMembershipShipsFilterEnum"},
            hangarGroupId: {type: :string, format: :uuid, nullable: true},
            fleetSlug: {type: :string},
            fleetName: {type: :string},
            fleet: {"$ref": "#/components/schemas/Fleet"},
            primary: {type: :boolean},
            hangarUpdatedAt: {type: :string, format: "date-time", nullable: true},
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
          required: %w[id username role roleLabel shipsFilter fleetSlug fleetName createdAt updatedAt]
        })
      end
    end
  end
end
