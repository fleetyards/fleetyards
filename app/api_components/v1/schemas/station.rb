# frozen_string_literal: true

module V1
  module Schemas
    class Station < StationMinimal
      include SchemaConcern

      schema({
        properties: {
          starsystem: {"$ref": "#/components/schemas/StarsystemMinimal"},
          shops: {type: :array, items: {"$ref": "#/components/schemas/ShopMinimal"}},
          docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
          habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},
          images: {type: :array, items: {"$ref": "#/components/schemas/ImageMinimal"}}
        }
      })
    end
  end
end
