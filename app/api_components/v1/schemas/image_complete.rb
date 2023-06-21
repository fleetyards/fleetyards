# frozen_string_literal: true

module V1
  module Schemas
    class ImageComplete < ImageMinimal
      include SchemaConcern

      schema({
        properties: {
          gallery: {"$ref" => "#/components/schemas/Gallery", :nullable => true},
          model: {"$ref" => "#/components/schemas/Gallery", :nullable => true}
        }
      })
    end
  end
end
