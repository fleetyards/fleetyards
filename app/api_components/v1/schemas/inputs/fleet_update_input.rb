# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetUpdateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            fid: {type: :string},
            name: {type: :string},
            logo: {type: :string, format: :binary},
            removeLogo: {type: :boolean},
            backgroundImage: {type: :string, format: :binary},
            removeBackground: {type: :boolean},
            description: {type: :string},
            publicFleet: {type: :boolean},
            homepage: {type: :string},
            rsiSid: {type: :string},
            discord: {type: :string},
            ts: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            guilded: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
