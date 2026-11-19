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
          # What the game's starmap lists the place as offering: where vehicle
          # services are, a ship can refuel.
          amenities: {type: :array, items: ::Shared::V1::Schemas::Enums::LocationAmenityEnum},
          lagrangePoint: {type: :boolean},
          gateway: {type: :boolean},
          color: {type: [:string, :null]},
          unstable: {type: :boolean},
          bodyType: ::Shared::V1::Schemas::Enums::NullableLocationBodyTypeEnum,
          # Whether a ship can dock or land there, by the hangars and pads it has.
          docking: {type: :boolean},
          # The surface the game's own starmap wraps a body in: equirectangular,
          # poles at the top and bottom edges. Null where the export has none.
          texture: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]},
          # Its terrain's elevation (a 16-bit greyscale map, unscaled) and cloud
          # cover (the red channel), both equirectangular and a quarter turn
          # round from the texture: the texture at u matches them at u + 0.25.
          elevation: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]},
          clouds: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]},
          # The colour of the ground, on a body the game's newer planet engine
          # paints: as near as the game files come to a picture of the planet
          # itself. Turned as the elevation is.
          ground: {anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]}
        },
        additionalProperties: false,
        required: %w[
          id name slug kind parentName parentId position radius shownOnStarmap
          shownWithParentOnly alwaysShown quantumTravelDestination amenities lagrangePoint
          gateway color unstable bodyType docking texture elevation clouds ground
        ]
      })
    end
  end
end
