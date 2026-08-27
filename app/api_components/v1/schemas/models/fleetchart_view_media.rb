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
            angledView: ::Shared::V1::Schemas::MediaFile,
            angledViewColored: ::Shared::V1::Schemas::MediaFile,
            frontView: ::Shared::V1::Schemas::MediaFile,
            frontViewColored: ::Shared::V1::Schemas::MediaFile,
            sideView: ::Shared::V1::Schemas::MediaFile,
            sideViewColored: ::Shared::V1::Schemas::MediaFile,
            topView: ::Shared::V1::Schemas::MediaFile,
            topViewColored: ::Shared::V1::Schemas::MediaFile,
            extendedAngledView: ::Shared::V1::Schemas::MediaFile,
            extendedAngledViewColored: ::Shared::V1::Schemas::MediaFile,
            extendedFrontView: ::Shared::V1::Schemas::MediaFile,
            extendedFrontViewColored: ::Shared::V1::Schemas::MediaFile,
            extendedSideView: ::Shared::V1::Schemas::MediaFile,
            extendedSideViewColored: ::Shared::V1::Schemas::MediaFile,
            extendedTopView: ::Shared::V1::Schemas::MediaFile,
            extendedTopViewColored: ::Shared::V1::Schemas::MediaFile
          }
        })
      end
    end
  end
end
