# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # The four package renders, identical in the public and the admin payload.
      class ModelModulePackageMedia
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            angledView: ::Shared::V1::Schemas::MediaFile,
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
