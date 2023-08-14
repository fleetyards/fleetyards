# frozen_string_literal: true

module V1
  module Schemas
    class FleetBase
      include SchemaConcern

      schema_hidden true

      schema({
        type: :object,
        properties: {
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
          backgroundImage: {type: :string, nullable: true}
        },
        additionalProperties: false,
        required: %w[id fid name slug publicFleet]
      })
    end
  end
end
