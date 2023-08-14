# frozen_string_literal: true

module V1
  module Schemas
    class FleetMembership
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          role: {"$ref": "#/components/schemas/FleetMembershipRoleEnum"},
          roleLabel: {type: :string},
          status: {"$ref": "#/components/schemas/FleetMembershipStatusEnum"},
          invitedAt: {type: :string, format: "date-time", nullable: true},
          requestedAt: {type: :string, format: "date-time", nullable: true},
          acceptedAt: {type: :string, format: "date-time", nullable: true},
          acceptedAtLabel: {type: :string, nullable: true},
          declinedAt: {type: :string, format: "date-time", nullable: true},
          declinedAtLabel: {type: :string, nullable: true},
          avatar: {type: :string, nullable: true},
          rsiHandle: {type: :string, nullable: true},
          homepage: {type: :string, nullable: true},
          discord: {type: :string, nullable: true},
          youtube: {type: :string, nullable: true},
          twitch: {type: :string, nullable: true},
          shipsFilter: {"$ref": "#/components/schemas/FleetMembershipShipsFilterEnum"},
          hangarGroupId: {type: :string, format: :uuid, nullable: true},
          fleetSlug: {type: :string},
          fleetName: {type: :string},
          fleet: {"$ref": "#/components/schemas/FleetMinimal"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id username role roleLabel shipsFilter fleetSlug fleetName fleet createdAt updatedAt]
      })
    end
  end
end
