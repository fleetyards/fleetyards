# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        module Paints
          class AdminModelPaintMedia
            include OpenapiRuby::Components::Base

            schema({
              type: :object,
              properties: {
                angledView: ::Shared::V1::Schemas::MediaFile,
                angledViewColored: ::Shared::V1::Schemas::MediaFile,
                fleetchartImage: {type: :string},
                frontView: ::Shared::V1::Schemas::MediaFile,
                frontViewColored: ::Shared::V1::Schemas::MediaFile,
                sideView: ::Shared::V1::Schemas::MediaFile,
                sideViewColored: ::Shared::V1::Schemas::MediaFile,
                rsiStoreImage: ::Shared::V1::Schemas::MediaFile,
                storeImage: ::Shared::V1::Schemas::MediaFile,
                topView: ::Shared::V1::Schemas::MediaFile,
                topViewColored: ::Shared::V1::Schemas::MediaFile
              },
              additionalProperties: false
            })
          end
        end
      end
    end
  end
end
