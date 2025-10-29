# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class Model < ::V1::Schemas::Models::Model
          include SchemaConcern

          schema({
            properties: {
              hidden: {type: :boolean},
              active: {type: :boolean},
              scLength: {type: :number},
              scBeam: {type: :number},
              scHeight: {type: :number},
              media: {
                type: :object,
                properties: {
                  angledView: {"$ref": "#/components/schemas/MediaFile"},
                  angledViewColored: {"$ref": "#/components/schemas/MediaFile"},
                  fleetchartImage: {type: :string},
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
