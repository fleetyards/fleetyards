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
              angledView: ::Shared::V1::Schemas::MediaFile,
              fleetchartImage: {type: :string},
              # frontView: ::Shared::V1::Schemas::MediaFile,
              # Repaints the model's textured holo: its body's base-colour map,
              # and its occlusion/roughness/metallic map.
              holoTexture: {type: [:string, :null]},
              holoTextureOrm: {type: [:string, :null]},
              portView: ::Shared::V1::Schemas::MediaFile,
              storeImage: ::Shared::V1::Schemas::MediaFile,
              topView: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
