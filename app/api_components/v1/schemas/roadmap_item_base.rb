# frozen_string_literal: true

module V1
  module Schemas
    class RoadmapItemBase
      include SchemaConcern

      schema_hidden true

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          release: {type: :string},
          releaseDescription: {type: :string},
          rsiReleaseId: {type: :integer},
          description: {type: :string},
          body: {type: :string},
          rsiCategoryId: {type: :integer},
          image: {type: :string},
          media: {
            type: :object,
            properties: {
              storeImage: {"$ref": "#/components/schemas/MediaImage", nullable: true}
            }
          },
          released: {type: :boolean},
          committed: {type: :boolean},
          active: {type: :boolean},
          storeImage: {type: :string, deprecated: true},
          storeImageLarge: {type: :string, deprecated: true},
          storeImageMedium: {type: :string, deprecated: true},
          storeImageSmall: {type: :string, deprecated: true}
        },
        additionalProperties: false,
        required: %w[
          id name release rsiReleaseId description body rsiCategoryId image released committed active
        ]
      })
    end
  end
end
