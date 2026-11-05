# frozen_string_literal: true

module V1
  module Schemas
    class SearchFleet
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          logo: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[name slug]
      })
    end
  end
end
