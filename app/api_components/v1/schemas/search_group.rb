# frozen_string_literal: true

module V1
  module Schemas
    # One catalogue's matches.
    class SearchGroup
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          type: {type: :string},
          items: {type: :array, items: ::V1::Schemas::SearchResult},
          hasMore: {type: :boolean, description: "Whether the catalogue has matches beyond these items"}
        },
        additionalProperties: false,
        required: %w[type items hasMore]
      })
    end
  end
end
