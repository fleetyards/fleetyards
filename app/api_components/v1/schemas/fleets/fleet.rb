# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class Fleet
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            myRole: {"$ref": "#/components/schemas/FleetMembershipRoleEnum"},
            primary: {type: :boolean},
            myFleet: {type: :boolean},
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            rsiSid: {type: :string, nullable: true},
            ts: {type: :string, nullable: true},
            discord: {type: :string, nullable: true},
            youtube: {type: :string, nullable: true},
            twitch: {type: :string, nullable: true},
            guilded: {type: :string, nullable: true},
            homepage: {type: :string, nullable: true},
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string, nullable: true},
            publicFleet: {type: :boolean},
            logo: {type: :string, nullable: true},
            backgroundImage: {type: :string, nullable: true},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fid name slug publicFleet createdAt updatedAt]
        })
      end
    end
  end
end
