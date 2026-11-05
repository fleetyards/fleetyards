# frozen_string_literal: true

module V1
  module Schemas
    # A few of the best matches per catalogue, the catalogue with the
    # strongest match first.
    class SearchResults
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          groups: {type: :array, items: ::V1::Schemas::SearchGroup},
          # Present where the search covered one fleet.
          fleet: {
            type: :object,
            properties: {
              name: {type: :string},
              slug: {type: :string},
              logo: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[name slug]
          }
        },
        additionalProperties: false,
        required: %w[groups]
      })
    end
  end
end
