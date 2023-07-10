# frozen_string_literal: true

module V1
  module Schemas
    class ModelModuleMinimal < ModelModule
      include SchemaConcern

      schema({
        properties: {
          manufacturer: {"$ref": "#/components/schemas/Manufacturer", nullable: true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[createdAt updatedAt]
      })
    end
  end
end
