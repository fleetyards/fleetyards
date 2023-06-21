# frozen_string_literal: true

module V1
  module Schemas
    class ModelComplete < ModelMinimal
      include SchemaConcern

      schema({
        properties: {
          dockCounts: {
            type: :array,
            items: {"$ref": "#/components/schemas/DockCount"}
          },
          links: {
            type: :object,
            properties: {
              self: {type: :string, format: :uri},
              frontend: {type: :string, format: :uri}
            }
          }
        },
        required: %w[dockCounts links]
      })
    end
  end
end
