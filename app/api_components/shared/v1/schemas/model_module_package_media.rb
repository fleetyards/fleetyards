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
            angledExtent: {
              type: :number,
              description: "How wide the angled picture is, as a share of the ship's length"
            },
            angledView: ::Shared::V1::Schemas::MediaFile,
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
