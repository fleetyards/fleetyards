# frozen_string_literal: true

module V1
  module Schemas
    # Places of one name inside one parent: a count above one is namesakes
    # folded together, and `location` is the first of them.
    class LocationContentsEntry
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: [:string, :null]},
          count: {type: :integer},
          shownOnStarmap: {type: :boolean},
          location: ::Shared::V1::Schemas::LocationLink
        },
        additionalProperties: false,
        required: %w[name count shownOnStarmap location]
      })
    end
  end
end
