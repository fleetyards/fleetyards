# frozen_string_literal: true

module V1
  module Schemas
    module Queries
      class LocationQuery
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            nameCont: {type: :string},
            idIn: {type: :array, items: {type: :string, format: :uuid}},
            nameIn: {type: :array, items: {type: :string}},

            kindEq: ::Shared::V1::Schemas::Enums::LocationKindEnum,
            kindIn: {type: :array, items: ::Shared::V1::Schemas::Enums::LocationKindEnum},

            # The places inside one, which is how a page lists its children.
            parentIdEq: {type: :string, format: :uuid},
            systemIdEq: {type: :string, format: :uuid},

            shownOnStarmapEq: {type: :boolean},
            quantumTravelDestinationEq: {type: :boolean},

            currentVersion: {type: :boolean},
            s: ::V1::Schemas::Enums::LocationSortingEnum,
            sorts: {type: :array, items: ::V1::Schemas::Enums::LocationSortingEnum}
          },
          additionalProperties: false,
          example: {}
        })
      end
    end
  end
end
