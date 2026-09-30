# frozen_string_literal: true

module V1
  module Schemas
    class MarkdownImage
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        required: %i[id url width height],
        properties: {
          id: {type: :string, format: :uuid},
          url: {type: :string, format: :uri, description: "The address to embed. It redirects to a re-encoded WebP rendition of the upload, never the original file, and stops resolving once the image is deleted."},
          width: {type: [:integer, :null]},
          height: {type: [:integer, :null]}
        }
      })
    end
  end
end
