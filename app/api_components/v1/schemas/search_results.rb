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
          groups: {type: :array, items: ::V1::Schemas::SearchGroup}
        },
        additionalProperties: false,
        required: %w[groups]
      })
    end
  end
end
