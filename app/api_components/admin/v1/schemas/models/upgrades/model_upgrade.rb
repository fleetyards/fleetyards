# frozen_string_literal: true

module Admin
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
                name: {type: :string},
                description: {type: :string},
                pledgePrice: {type: :number},

                media: {
                  type: :object,
                  properties: {
                    storeImage: {"$ref": "#/components/schemas/MediaImage"}
                  },
                  additionalProperties: false
                },

                createdAt: {type: :string, format: "date-time"},
                updatedAt: {type: :string, format: "date-time"},

                # DEPRECATED

                storeImage: {type: :string, format: :uri, deprecated: true},
                storeImageLarge: {type: :string, format: :uri, deprecated: true},
                storeImageMedium: {type: :string, format: :uri, deprecated: true},
                storeImageSmall: {type: :string, format: :uri, deprecated: true}
              },
              additionalProperties: false,
              required: %w[id name media createdAt updatedAt]
            })
          end
        end
      end
    end
  end
end
