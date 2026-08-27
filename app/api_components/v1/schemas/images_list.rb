# frozen_string_literal: true

module V1
  module Schemas
    class ImagesList
      include OpenapiRuby::Components::Base

      # Images is the paginated collection; GET /images/random returns a bare array.

      schema({
        type: :array,
        items: {"$ref": "#/components/schemas/Image"}
      })
    end
  end
end
