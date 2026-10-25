# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A catalogue item's pictures. The views and the holo are rendered on the
      # detail payload, the way a ship's are; a public list leaves them out, and
      # an admin list carries only the angled view.
      class ItemMedia
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            storeImage: ::Shared::V1::Schemas::MediaFile,
            topView: ::Shared::V1::Schemas::MediaFile,
            portView: ::Shared::V1::Schemas::MediaFile,
            frontView: ::Shared::V1::Schemas::MediaFile,
            angledView: ::Shared::V1::Schemas::MediaFile,
            angledRearView: ::Shared::V1::Schemas::MediaFile,
            bottomView: ::Shared::V1::Schemas::MediaFile,
            rearView: ::Shared::V1::Schemas::MediaFile,
            starboardView: ::Shared::V1::Schemas::MediaFile,
            holo: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false
        })
      end
    end
  end
end
