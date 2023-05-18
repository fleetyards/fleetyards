# frozen_string_literal: true

module V1
  module Schemas
    class Starsystem
      include SchemaConcern

      schema :base, {
        type: :object,
        properties: {
          name: {type: :string},
          slug: {type: :string},
          storeImage: {type: :string},
          storeImageLarge: {type: :string},
          storeImageMedium: {type: :string},
          storeImageSmall: {type: :string},
          mapX: {type: :string, nullable: true},
          mapY: {type: :string, nullable: true},
          description: {type: :string, nullable: true},
          type: {type: :string, nullable: true},
          size: {type: :string, nullable: true},
          population: {type: :string, nullable: true},
          economy: {type: :string, nullable: true},
          danger: {type: :string, nullable: true},
          status: {type: :string, nullable: true},
          locationLabel: {type: :string, nullable: true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        required: %w[name slug createdAt updatedAt]
      }
    end
  end
end
