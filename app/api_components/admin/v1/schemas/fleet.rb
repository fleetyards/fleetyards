# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Fleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string},
            rsiSid: {type: :string},
            rsiVerified: {type: :boolean},
            rsiVerifiedAt: {type: :string, format: "date-time"},
            rsiMemberCount: {type: [:integer, :null], description: "Members of the verified RSI org. Null until RSI has been asked"},
            ts: {type: :string},
            discord: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            guilded: {type: :string},
            homepage: {type: :string},
            # Where the fleet is based: free text, linked to one of our places where
            # it is one.
            headquarters: {type: [:string, :null]},
            headquartersLocation: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            memberCount: {type: :integer, description: "Accepted members. Only the fleets list sends it"},
            logo: ::Shared::V1::Schemas::MediaFile,
            backgroundImage: ::Shared::V1::Schemas::MediaFile,
            fleetRoles: {
              type: :array,
              items: ::Admin::V1::Schemas::AdminFleetRole
            },
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fid name slug publicFleet publicFleetStats fleetRoles createdAt updatedAt]
        })
      end
    end
  end
end
