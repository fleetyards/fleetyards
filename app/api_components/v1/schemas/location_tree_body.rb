# frozen_string_literal: true

module V1
  module Schemas
    class LocationTreeBody
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          slug: {type: :string},
          kind: ::Shared::V1::Schemas::Enums::LocationKindEnum,
          parentName: {type: [:string, :null]},
          shownOnStarmap: {type: :boolean},
          color: {type: [:string, :null]},
          # A star the game describes as a flare star, as it does Pyro's.
          unstable: {type: :boolean},
          bodyType: ::Shared::V1::Schemas::Enums::NullableLocationBodyTypeEnum,
          image: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[id slug kind parentName shownOnStarmap color]
      })
    end
  end
end
