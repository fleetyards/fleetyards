# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      # A fleet as the public directory lists it: who it is and what it is
      # about, without the settings the fleet page carries.
      class FleetDirectoryEntry
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            fid: {type: :string},
            slug: {type: :string},
            name: {type: :string},
            rsiSid: {type: :string},
            memberCount: {type: [:integer, :null], description: "Members of the RSI org. Null until RSI has been asked"},
            alignment: ::V1::Schemas::Enums::NullableFleetAlignmentEnum,
            primaryActivity: ::V1::Schemas::Enums::NullableFleetActivityEnum,
            secondaryActivity: ::V1::Schemas::Enums::NullableFleetActivityEnum,
            commitment: ::V1::Schemas::Enums::NullableFleetCommitmentEnum,
            language: ::V1::Schemas::Enums::NullableFleetLanguageEnum,
            roleplay: {type: [:boolean, :null]},
            recruiting: {type: [:boolean, :null]},
            defaultTimezone: {type: :string},
            logo: ::Shared::V1::Schemas::MediaFile,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id fid slug name rsiSid memberCount defaultTimezone createdAt updatedAt]
        })
      end
    end
  end
end
