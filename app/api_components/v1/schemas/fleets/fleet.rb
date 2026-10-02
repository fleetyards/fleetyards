# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      class Fleet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            rsiSid: {type: :string},
            rsiVerified: {type: :boolean},
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
            name: {type: :string},
            slug: {type: :string},
            description: {type: :string},
            publicFleet: {type: :boolean},
            publicFleetStats: {type: :boolean},
            alliesFleet: {type: :boolean},
            alliesFleetStats: {type: :boolean},
            alliesFleetMembers: {type: :boolean},
            squadronsEnabled: {type: :boolean},
            defaultTimezone: {type: :string},
            # Absent until a manager picks, and then it follows publicFleet.
            listed: {type: [:boolean, :null]},
            listedInDirectory: {type: :boolean},
            alignment: ::V1::Schemas::Enums::NullableFleetAlignmentEnum,
            # Synced from the fleet's RSI org once it is verified, never edited here.
            primaryActivity: ::V1::Schemas::Enums::NullableFleetActivityEnum,
            secondaryActivity: ::V1::Schemas::Enums::NullableFleetActivityEnum,
            commitment: ::V1::Schemas::Enums::NullableFleetCommitmentEnum,
            language: ::V1::Schemas::Enums::NullableFleetLanguageEnum,
            roleplay: {type: [:boolean, :null]},
            recruiting: {type: [:boolean, :null]},
            rsiSyncedAt: {type: [:string, :null], format: "date-time"},
            calendarFeedToken: {type: :string},
            logo: ::Shared::V1::Schemas::MediaFile,
            backgroundImage: ::Shared::V1::Schemas::MediaFile,
            contractCovers: ::V1::Schemas::Fleets::FleetContractCovers,
            myFleet: {type: :boolean},
            features: {type: :array, items: {type: :string}},
            # Whether the fleet holds an entitlement today. Separate from
            # `features`: that is what is rolled out here, this is what was
            # bought, and the two are asked independently.
            subscribed: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fid name slug publicFleet publicFleetStats alliesFleet alliesFleetStats alliesFleetMembers squadronsEnabled listedInDirectory features subscribed createdAt updatedAt]
        })
      end
    end
  end
end
