# frozen_string_literal: true

module V1
  module Schemas
    class Image < ImageMinimal
      include SchemaConcern

      schema({
        properties: {
          gallery: {"$ref": "#/components/schemas/Gallery", nullable: true},
          model: {"$ref": "#/components/schemas/Gallery", nullable: true}
        },
        additionalProperties: false
      })
    end
  end
end
