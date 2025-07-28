# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class Fleet
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            rsiSid: {type: :string},
            ts: {type: :string},
            discord: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            guilded: {type: :string},
            homepage: {type: :string},
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            logo: {type: :string},
            backgroundImage: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fid name slug publicFleet publicFleetStats createdAt updatedAt]
        })
      end
    end
  end
end
