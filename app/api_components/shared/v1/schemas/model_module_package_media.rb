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
            angledView: {"$ref": "#/components/schemas/MediaFile"},
            sideView: {"$ref": "#/components/schemas/MediaFile"},
            storeImage: {"$ref": "#/components/schemas/MediaFile"},
            topView: {"$ref": "#/components/schemas/MediaFile"}
          },
          additionalProperties: false
        })
      end
    end
  end
end
