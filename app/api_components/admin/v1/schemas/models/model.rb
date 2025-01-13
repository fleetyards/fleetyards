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
                  angledView: {"$ref": "#/components/schemas/ViewImage"},
                  angledViewColored: {"$ref": "#/components/schemas/ViewImage"},
                  fleetchartImage: {type: :string},
                  frontView: {"$ref": "#/components/schemas/ViewImage"},
                  frontViewColored: {"$ref": "#/components/schemas/ViewImage"},
                  sideView: {"$ref": "#/components/schemas/ViewImage"},
                  sideViewColored: {"$ref": "#/components/schemas/ViewImage"},
                  rsiStoreImage: {"$ref": "#/components/schemas/MediaImage"},
                  storeImage: {"$ref": "#/components/schemas/MediaImage"},
                  topView: {"$ref": "#/components/schemas/ViewImage"},
                  topViewColored: {"$ref": "#/components/schemas/ViewImage"}
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
