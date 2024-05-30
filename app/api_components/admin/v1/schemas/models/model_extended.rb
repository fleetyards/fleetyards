# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        class ModelExtended < Model
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
  end
end
