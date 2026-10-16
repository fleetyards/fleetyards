# frozen_string_literal: true

module V1
  module Schemas
    class ModelMedia
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          angledView: ::Shared::V1::Schemas::MediaFile,
          angledViewColored: ::Shared::V1::Schemas::MediaFile,
          fleetchartImage: {type: :string},
          extendedHolo: ::Shared::V1::Schemas::MediaFile,
          extendedTopView: ::Shared::V1::Schemas::MediaFile,
          extendedTopViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedPortView: ::Shared::V1::Schemas::MediaFile,
          extendedPortViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedFrontView: ::Shared::V1::Schemas::MediaFile,
          extendedFrontViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedAngledView: ::Shared::V1::Schemas::MediaFile,
          extendedAngledViewColored: ::Shared::V1::Schemas::MediaFile,
          landedHolo: ::Shared::V1::Schemas::MediaFile,
          landedTopView: ::Shared::V1::Schemas::MediaFile,
          landedTopViewColored: ::Shared::V1::Schemas::MediaFile,
          landedPortView: ::Shared::V1::Schemas::MediaFile,
          landedPortViewColored: ::Shared::V1::Schemas::MediaFile,
          landedFrontView: ::Shared::V1::Schemas::MediaFile,
          landedFrontViewColored: ::Shared::V1::Schemas::MediaFile,
          landedAngledView: ::Shared::V1::Schemas::MediaFile,
          landedAngledViewColored: ::Shared::V1::Schemas::MediaFile,
          frontView: ::Shared::V1::Schemas::MediaFile,
          frontViewColored: ::Shared::V1::Schemas::MediaFile,
          portView: ::Shared::V1::Schemas::MediaFile,
          portViewColored: ::Shared::V1::Schemas::MediaFile,
          storeImage: ::Shared::V1::Schemas::MediaFile,
          topView: ::Shared::V1::Schemas::MediaFile,
          topViewColored: ::Shared::V1::Schemas::MediaFile,
          holo: ::Shared::V1::Schemas::MediaFile,
          angledRearView: ::Shared::V1::Schemas::MediaFile,
          angledRearViewColored: ::Shared::V1::Schemas::MediaFile,
          bottomView: ::Shared::V1::Schemas::MediaFile,
          bottomViewColored: ::Shared::V1::Schemas::MediaFile,
          rearView: ::Shared::V1::Schemas::MediaFile,
          rearViewColored: ::Shared::V1::Schemas::MediaFile,
          starboardView: ::Shared::V1::Schemas::MediaFile,
          starboardViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedAngledRearView: ::Shared::V1::Schemas::MediaFile,
          extendedAngledRearViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedBottomView: ::Shared::V1::Schemas::MediaFile,
          extendedBottomViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedRearView: ::Shared::V1::Schemas::MediaFile,
          extendedRearViewColored: ::Shared::V1::Schemas::MediaFile,
          extendedStarboardView: ::Shared::V1::Schemas::MediaFile,
          extendedStarboardViewColored: ::Shared::V1::Schemas::MediaFile,
          landedAngledRearView: ::Shared::V1::Schemas::MediaFile,
          landedAngledRearViewColored: ::Shared::V1::Schemas::MediaFile,
          landedBottomView: ::Shared::V1::Schemas::MediaFile,
          landedBottomViewColored: ::Shared::V1::Schemas::MediaFile,
          landedRearView: ::Shared::V1::Schemas::MediaFile,
          landedRearViewColored: ::Shared::V1::Schemas::MediaFile,
          landedStarboardView: ::Shared::V1::Schemas::MediaFile,
          landedStarboardViewColored: ::Shared::V1::Schemas::MediaFile,
          holoLite: ::Shared::V1::Schemas::MediaFile,
          extendedHoloLite: ::Shared::V1::Schemas::MediaFile,
          landedHoloLite: ::Shared::V1::Schemas::MediaFile,
          holoTextured: ::Shared::V1::Schemas::MediaFile,
          brochure: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false

      })
    end
  end
end
