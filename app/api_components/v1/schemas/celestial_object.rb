# frozen_string_literal: true

module V1
  module Schemas
    class CelestialObject < CelestialObjectMinimal
      include SchemaConcern

      schema({
        properties: {
          parent: {"$ref": "#/components/schemas/CelestialObject", nullable: true},
          moons: {type: :array, items: {"$ref" => "#/components/schemas/CelestialObject"}}
        },
        additionalProperties: false
      })
    end
  end
end
