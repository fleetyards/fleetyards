# frozen_string_literal: true

module V1
  module Schemas
    module Models
      # The subset of ModelMedia a fleetchart draws with.
      class FleetchartViewMedia
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            angledView: {"$ref": "#/components/schemas/MediaFile"},
            angledViewColored: {"$ref": "#/components/schemas/MediaFile"},
            frontView: {"$ref": "#/components/schemas/MediaFile"},
            frontViewColored: {"$ref": "#/components/schemas/MediaFile"},
            sideView: {"$ref": "#/components/schemas/MediaFile"},
            sideViewColored: {"$ref": "#/components/schemas/MediaFile"},
            topView: {"$ref": "#/components/schemas/MediaFile"},
            topViewColored: {"$ref": "#/components/schemas/MediaFile"},
            extendedAngledView: {"$ref": "#/components/schemas/MediaFile"},
            extendedAngledViewColored: {"$ref": "#/components/schemas/MediaFile"},
            extendedFrontView: {"$ref": "#/components/schemas/MediaFile"},
            extendedFrontViewColored: {"$ref": "#/components/schemas/MediaFile"},
            extendedSideView: {"$ref": "#/components/schemas/MediaFile"},
            extendedSideViewColored: {"$ref": "#/components/schemas/MediaFile"},
            extendedTopView: {"$ref": "#/components/schemas/MediaFile"},
            extendedTopViewColored: {"$ref": "#/components/schemas/MediaFile"}
          }
        })
      end
    end
  end
end
