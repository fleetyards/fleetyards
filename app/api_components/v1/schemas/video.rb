# frozen_string_literal: true

module V1
  module Schemas
    class Video
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          type: {"$ref": "#/components/schemas/VideoTypeEnum"},
          url: {type: :string, format: :uri},
          videoId: {type: :string, nullable: true},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id url videoId type createdAt updatedAt]
      })
    end
  end
end
