# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class FleetInput
          include Rswag::SchemaComponents::Component

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              fid: {type: :string},
              description: {type: :string},
              publicFleet: {type: :boolean},
              publicFleetStats: {type: :boolean},
              discord: {type: :string},
              guilded: {type: :string},
              homepage: {type: :string},
              twitch: {type: :string},
              youtube: {type: :string},
              ts: {type: :string},
              rsiSid: {type: :string},
              logo: {type: :string},
              backgroundImage: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
