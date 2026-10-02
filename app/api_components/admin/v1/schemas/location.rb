# frozen_string_literal: true

module Admin
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
            scKey: {type: :string},
            # Every record the place came from: more than one for a place the
            # overrides merge from copies, or that folds a namesake child in.
            scRefs: {type: :array, items: {type: :string}},
            gameType: {type: [:string, :null]},
            # Null once a load no longer carries the place.
            version: {type: [:string, :null]},
            retired: {type: :boolean},
            shownOnStarmap: {type: :boolean},
            shownWithParentOnly: {type: :boolean},
            alwaysShown: {type: :boolean},
            quantumTravelDestination: {type: :boolean},
            parent: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},

            # Detail responses only.
            description: {type: [:string, :null]},
            color: {type: [:string, :null]},
            drawnColor: {type: [:string, :null]},
            unstable: {type: :boolean},
            bodyType: ::Shared::V1::Schemas::Enums::NullableLocationBodyTypeEnum,
            image: ::Shared::V1::Schemas::MediaFile,
            mapParent: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
            system: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
            childrenCount: {type: :integer},
            gameMissionsCount: {type: :integer},
            missionTemplateRefs: {type: :array, items: {type: :string}},
            terminals: {type: :array, items: ::Admin::V1::Schemas::LocationTerminal},
            shops: {type: :array, items: ::Admin::V1::Schemas::LocationShop},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id slug kind scKey scRefs version retired shownOnStarmap
            shownWithParentOnly alwaysShown quantumTravelDestination parent
            createdAt updatedAt
          ]
        })
      end
    end
  end
end
