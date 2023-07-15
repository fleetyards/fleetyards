# frozen_string_literal: true

module V1
  module Schemas
    class Video
      include SchemaConcern

      schema_hidden true

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          type: {"$ref": "#/components/schemas/VideoTypeEnum"},
          url: {type: :string, format: :uri},
          videoId: {type: :string, nullable: true}
        },
        additionalProperties: false,
        required: %w[id url videoId type]
      })
    end
  end
end
