# frozen_string_literal: true

module V1
  module Schemas
    class HangarImportResult
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          success: {type: :boolean},
          missing: {type: :array, items: {type: :string}},
          imported: {type: :array, items: {type: :string}}
        },
        additionalProperties: false,
        required: %w[success missing imported]
      })
    end
  end
end
