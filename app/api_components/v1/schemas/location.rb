# frozen_string_literal: true

module V1
  module Schemas
    class Location
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: :string},
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,

          # The record key, `StarMapObject.<key>`, and the game's own type name.
          scKey: {type: :string},
          gameType: {type: [:string, :null]},

          retired: {type: :boolean},

          # How the in-game map shows the place. 1107 of the 1847 are hidden on
          # it -- clinics, habs, the rooms inside a station.
          shownOnStarmap: {type: :boolean},
          shownWithParentOnly: {type: :boolean},
          alwaysShown: {type: :boolean},
          quantumTravelDestination: {type: :boolean},

          # Null for a system.
          parent: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},

          # Detail responses only.
          description: {type: [:string, :null]},
          color: {type: [:string, :null]},
          unstable: {type: :boolean},
          bodyType: ::Shared::V1::Schemas::Enums::NullableLocationBodyTypeEnum,
          image: ::Shared::V1::Schemas::MediaFile,
          resources: {type: :array, items: ::V1::Schemas::LocationResourceGroup},
          # Null where the game places no hangar, pad or docking tube, and for
          # every place in a build from before they were counted.
          facilities: {anyOf: [::V1::Schemas::LocationFacilities, {type: :null}]},
          ancestors: {type: :array, items: ::Shared::V1::Schemas::LocationLink},
          # Where the game's map draws the place, when that is not where it is:
          # Levski under the Nyx star, while it sits inside Delamar.
          mapParent: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
          childrenCount: {type: :integer},
          # Every place in the system this one is in.
          placesCount: {type: :integer},
          terminals: {type: :array, items: ::V1::Schemas::LocationTerminal},

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[
          id slug kind scKey retired shownOnStarmap shownWithParentOnly
          alwaysShown quantumTravelDestination parent createdAt updatedAt
        ]
      })
    end
  end
end
