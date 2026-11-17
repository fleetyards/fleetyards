# frozen_string_literal: true

module V1
  module Schemas
    # A place the game positions on its starmap.
    class LocationStarmapPlace
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: :string},
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          parentName: {type: [:string, :null]},
          parentId: {type: [:string, :null], format: :uuid},
          # Metres in system space, the star at the origin.
          position: {type: :array, items: {type: :number}, minItems: 3, maxItems: 3},
          # A star's, planet's or moon's radius in metres. Null for every other
          # place.
          radius: {type: [:number, :null]},
          shownOnStarmap: {type: :boolean},
          shownWithParentOnly: {type: :boolean},
          alwaysShown: {type: :boolean},
          quantumTravelDestination: {type: :boolean},
          lagrangePoint: {type: :boolean},
          gateway: {type: :boolean},
          color: {type: [:string, :null]},
          unstable: {type: :boolean},
          bodyType: ::Shared::V1::Schemas::Enums::NullableLocationBodyTypeEnum
        },
        additionalProperties: false,
        required: %w[
          id name slug kind parentName parentId position radius shownOnStarmap
          shownWithParentOnly alwaysShown quantumTravelDestination lagrangePoint
          gateway color unstable bodyType
        ]
      })
    end
  end
end
