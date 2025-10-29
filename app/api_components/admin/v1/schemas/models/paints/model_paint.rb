# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Paints
          class ModelPaint < ::V1::Schemas::Models::Paints::ModelPaint
            include SchemaConcern

            schema({
              properties: {
                hidden: {type: :boolean},
                active: {type: :boolean},
                model: {"$ref": "#/components/schemas/Model"},
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
              required: %w[hidden active media model]
            })
          end
        end
      end
    end
  end
end
