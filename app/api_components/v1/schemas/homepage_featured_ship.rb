# frozen_string_literal: true

module V1
  module Schemas
    class HomepageFeaturedShip
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          manufacturerName: {type: :string},
          # The ship's angled render where it has one, else its store image.
          image: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[name slug]
      })
    end
  end
end
