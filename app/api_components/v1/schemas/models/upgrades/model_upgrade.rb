# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Upgrades
        class ModelUpgrade
          include SchemaConcern

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string, nullable: true},
              description: {type: :string, nullable: true},
              pledgePrice: {type: :number, nullable: true},

              media: {
                type: :object,
                properties: {
                  storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
                },
                additionalProperties: false
              },

              createdAt: {type: :string, format: "date-time"},
              updatedAt: {type: :string, format: "date-time"},

              # DEPRECATED

              storeImage: {type: :string, format: :uri, nullable: true, deprecated: true},
              storeImageLarge: {type: :string, format: :uri, nullable: true, deprecated: true},
              storeImageMedium: {type: :string, format: :uri, nullable: true, deprecated: true},
              storeImageSmall: {type: :string, format: :uri, nullable: true, deprecated: true}
            },
            additionalProperties: false,
            required: %w[id name media createdAt updatedAt]
          })
        end
      end
    end
  end
end
