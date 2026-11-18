# frozen_string_literal: true

module V1
  module Schemas
    # A system and every place in it the game positions on its starmap.
    class LocationStarmap
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          system: ::Shared::V1::Schemas::LocationLink,
          places: {type: :array, items: ::V1::Schemas::LocationStarmapPlace}
        },
        additionalProperties: false,
        required: %w[system places]
      })
    end
  end
end
