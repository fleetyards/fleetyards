# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Station
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            cargoHub: {type: :boolean},
            celestialObject: {"$ref": "#/components/schemas/CelestialObject"},
            classificationLabel: {type: :string, nullable: true},
            classification: {type: :string, nullable: true},
            description: {type: :string, nullable: true},
            dockCounts: {type: :array, items: {"$ref": "#/components/schemas/DockCount"}},
            habitable: {type: :boolean},
            habitationCounts: {type: :array, items: {"$ref": "#/components/schemas/HabitationCount"}},
            hasImages: {type: :boolean},
            locationLabel: {type: :string, nullable: true},
            location: {type: :string, nullable: true},

            media: {
              type: :object,
              properties: {
                backgroundImage: {type: :string, nullable: true},
                storeImage: {"$ref": "#/components/schemas/MediaImage"}
              },
              additionalProperties: false
            },

            refinery: {type: :boolean},
            shopListLabel: {type: :string, nullable: true},
            typeLabel: {type: :string, nullable: true},
            type: {type: :string, nullable: true},

            starsystem: {"$ref": "#/components/schemas/Starsystem"},
            shops: {type: :array, items: {"$ref": "#/components/schemas/Shop"}},
            docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
            habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            id name slug habitable hasImages refinery cargoHub celestialObject createdAt
            updatedAt
          ]
        })
      end
    end
  end
end
