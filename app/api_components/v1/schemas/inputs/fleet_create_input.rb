# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetCreateInput
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            fid: {type: :string, format: :uuid},
            name: {type: :string},
            description: {type: :string},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            homepage: {type: :string},
            rsiSid: {type: :string},
            discord: {type: :string},
            ts: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            guilded: {type: :string}
          },
          additionalProperties: false,
          required: %w[fid name]
        })
      end
    end
  end
end
