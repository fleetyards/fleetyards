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
          url: {type: :string, format: :uri, description: "A re-encoded WebP rendition of the upload, never the original file"},
          width: {type: [:integer, :null]},
          height: {type: [:integer, :null]}
        }
      })
    end
  end
end
