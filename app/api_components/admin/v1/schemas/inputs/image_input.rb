# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ImageInput
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              caption: {type: :string},
              enabled: {type: :boolean},
              global: {type: :boolean},
              background: {type: :boolean},
              galleryId: {type: :string, format: :uuid},
              galleryType: {"$ref": "#/components/schemas/GalleryTypeEnum"}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
