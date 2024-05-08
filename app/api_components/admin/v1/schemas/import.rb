# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Import
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},

            type: {"$ref": "#/components/schemas/ImportTypeEnum"},
            status: {"$ref": "#/components/schemas/ImportStatusEnum"},
            info: {type: :string},
            version: {type: :string},

            input: {type: :string},
            output: {type: :string},
            import: {type: :string},
            importData: {type: :string},

            startedAt: {type: :string, format: "date-time"},
            finishedAt: {type: :string, format: "date-time"},
            failedAt: {type: :string, format: "date-time"},

            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id type status createdAt updatedAt]
        })
      end
    end
  end
end
