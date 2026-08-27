# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Paints
        class ModelPaintMedia
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              angledView: {"$ref": "#/components/schemas/MediaFile"},
              fleetchartImage: {type: :string},
              # frontView: {"$ref": "#/components/schemas/MediaFile"},
              sideView: {"$ref": "#/components/schemas/MediaFile"},
              storeImage: {"$ref": "#/components/schemas/MediaFile"},
              topView: {"$ref": "#/components/schemas/MediaFile"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
