# frozen_string_literal: true

module V1
  module Schemas
    class SearchResult
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          type: {type: :string},
          name: {type: :string},
          slug: {type: :string},
          # Absent rather than null when there is nothing to tell the item
          # apart by: `Jbuilder.ignore_nil` drops the key.
          detail: {type: :string},
          # Absent where the catalogue keeps no picture, or this item has none.
          image: ::Shared::V1::Schemas::MediaFile,
          # Present for a place only.
          appearance: ::V1::Schemas::SearchAppearance
        },
        additionalProperties: false,
        required: %w[type name slug]
      })
    end
  end
end
