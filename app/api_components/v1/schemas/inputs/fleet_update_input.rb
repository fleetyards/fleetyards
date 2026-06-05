# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class FleetUpdateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            fid: {type: [:string, :null]},
            name: {type: [:string, :null]},
            logo: {type: [:string, :null]},
            removeLogo: {type: :boolean},
            backgroundImage: {type: [:string, :null], format: :binary},
            removeBackground: {type: :boolean},
            description: {type: [:string, :null]},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            homepage: {type: [:string, :null]},
            rsiSid: {type: [:string, :null]},
            discord: {type: [:string, :null]},
            ts: {type: [:string, :null]},
            youtube: {type: [:string, :null]},
            twitch: {type: [:string, :null]},
            guilded: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
