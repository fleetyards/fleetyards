# frozen_string_literal: true

module V1
  module Schemas
    class Image < ::Shared::V1::Schemas::MediaFile
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          background: {type: :boolean},
          caption: {type: :string},
          gallery: {"$ref": "#/components/schemas/Gallery"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id background createdAt updatedAt]
      })
    end
  end
end
