# frozen_string_literal: true

module V1
  module Schemas
    class ModelUpgrade
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string, nullable: true},

          description: {type: :string, nullable: true},
          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage"}
            }
          },
          pledgePrice: {type: :number, nullable: true},

          storeImage: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
          storeImageSmall: {type: :string, format: :uri, nullable: true, deprecated: true}
        },
        additionalProperties: false,
        required: %w[id name media]
      })
    end
  end
end
