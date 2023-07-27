# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Shop
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},

            buying: {type: :boolean},
            location: {type: :string, nullable: true},
            locationLabel: {type: :string},
            media: {
              type: :object,
              properties: {
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              }
            },
            refineryTerminal: {type: :boolean},
            rental: {type: :boolean},
            selling: {type: :boolean},
            station: {"$ref": "#/components/schemas/StationShop"},
            stationLabel: {type: :string},
            type: {"$ref": "#/components/schemas/ShopTypeEnum"},
            typeLabel: {type: :string},

            storeImage: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageSmall: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageMedium: {type: :string, nullable: true, format: :uri, deprecated: true},
            storeImageLarge: {type: :string, nullable: true, format: :uri, deprecated: true}
          },
          additionalProperties: false,
          required: %w[
            id name slug type typeLabel stationLabel locationLabel rental buying selling
            refineryTerminal station
          ]
        })
      end
    end
  end
end
