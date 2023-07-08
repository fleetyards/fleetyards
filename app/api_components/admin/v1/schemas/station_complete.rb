# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class StationComplete < StationMinimal
        include SchemaConcern

        schema({
          properties: {
            starsystem: {"$ref": "#/components/schemas/Starsystem"},
            shops: {type: :array, items: {"$ref": "#/components/schemas/Shop"}},
            docks: {type: :array, items: {"$ref": "#/components/schemas/Dock"}},
            habitations: {type: :array, items: {"$ref": "#/components/schemas/Habitation"}},
            images: {type: :array, items: {"$ref": "#/components/schemas/Image"}}
          }
        })
      end
    end
  end
end
