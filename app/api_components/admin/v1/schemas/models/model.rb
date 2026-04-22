# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class Model < ::V1::Schemas::Models::Model
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              hidden: {type: :boolean},
              active: {type: :boolean},
              scKey: {type: :string},
              positionsNeedCuration: {type: :boolean},
              scLength: {type: :number},
              scBeam: {type: :number},
              scHeight: {type: :number},
              media: {
                type: :object,
                properties: {
                  angledView: {"$ref": "#/components/schemas/MediaFile"},
                  angledViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  fleetchartImage: {type: :string},
                  extendedHolo: {"$ref": "#/components/schemas/MediaFile"},
                  extendedTopView: {"$ref": "#/components/schemas/MediaFile"},
                  extendedTopViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  extendedSideView: {"$ref": "#/components/schemas/MediaFile"},
                  extendedSideViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  extendedFrontView: {"$ref": "#/components/schemas/MediaFile"},
                  extendedFrontViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  extendedAngledView: {"$ref": "#/components/schemas/MediaFile"},
                  extendedAngledViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  frontView: {"$ref": "#/components/schemas/MediaFile"},
                  frontViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  sideView: {"$ref": "#/components/schemas/MediaFile"},
                  sideViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  rsiStoreImage: {"$ref": "#/components/schemas/MediaFile"},
                  storeImage: {"$ref": "#/components/schemas/MediaFile"},
                  topView: {"$ref": "#/components/schemas/MediaFile"},
                  topViewColored: {"$ref": "#/components/schemas/MediaFile"}
                },
                additionalProperties: false
              }
            },
            required: %w[hidden active media]
          })
        end
      end
    end
  end
end
