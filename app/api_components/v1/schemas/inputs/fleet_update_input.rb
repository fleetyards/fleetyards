# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fid: {type: :string, nullable: true},
            name: {type: :string, nullable: true},
            logo: {type: :string, nullable: true},
            removeLogo: {type: :boolean},
            backgroundImage: {type: :string, format: :binary, nullable: true},
            removeBackground: {type: :boolean},
            description: {type: :string, nullable: true},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            homepage: {type: :string, nullable: true},
            rsiSid: {type: :string, nullable: true},
            discord: {type: :string, nullable: true},
            ts: {type: :string, nullable: true},
            youtube: {type: :string, nullable: true},
            twitch: {type: :string, nullable: true},
            guilded: {type: :string, nullable: true}
          },
          additionalProperties: false
        })
      end
    end
  end
end
