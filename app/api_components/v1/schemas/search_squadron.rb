# frozen_string_literal: true

module V1
  module Schemas
    # What a search result needs to draw a member's squadron.
    class SearchSquadron
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          color: {type: :string},
          icon: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[name]
      })
    end
  end
end
