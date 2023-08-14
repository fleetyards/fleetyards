# frozen_string_literal: true

module V1
  module Schemas
    class Model < ModelMinimal
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
        additionalProperties: false,
        required: %w[dockCounts links]
      })
    end
  end
end
