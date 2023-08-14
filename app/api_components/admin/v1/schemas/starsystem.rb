# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Starsystem < StarsystemMinimal
        include SchemaConcern

        schema({
          properties: {
            celestialObjects: {type: :array, items: {"$ref": "#/components/schemas/CelestialObject"}}
          },
          additionalProperties: false,
          required: %w[celestialObjects]
        })
      end
    end
  end
end
