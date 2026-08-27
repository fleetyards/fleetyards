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
              sideView: ::Shared::V1::Schemas::MediaFile,
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
