# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObject
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          designation: {type: :string},
          storeImageIsFallback: {type: :boolean},
          storeImage: {type: :string, format: :url},
          storeImageLarge: {type: :string},
          storeImageMedium: {type: :string},
          storeImageSmall: {type: :string},
          description: {type: :string, nullable: true},
          type: {type: :string, nullable: true},
          habitable: {type: :boolean, nullable: true},
          fairchanceact: {type: :boolean, nullable: true},
          subType: {type: :string, nullable: true},
          size: {type: :string, nullable: true},
          danger: {type: :integer, nullable: true},
          economy: {type: :integer, nullable: true},
          population: {type: :integer, nullable: true},
          locationLabel: {type: :string, nullable: true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[name slug designation createdAt updatedAt]
      }

      schema :minimal, {
        properties: {
          starsystem: {"$ref" => "#/components/schemas/Starsystem"},
          parent: {"$ref" => "#/components/schemas/CelestialObject", :nullable => true},
          moons: {type: :array, items: {"$ref" => "#/components/schemas/CelestialObject"}}
        },
        required: %w[starsystem]
      }, extends: :base
    end
  end
end
