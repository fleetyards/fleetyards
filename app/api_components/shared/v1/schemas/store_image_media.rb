# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class StoreImageMedia
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            storeImage: {"$ref": "#/components/schemas/MediaFile"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
