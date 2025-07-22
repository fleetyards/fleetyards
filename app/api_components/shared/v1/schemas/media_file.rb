# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class MediaFile
        include SchemaConcern

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            contentType: {type: :string},
            size: {type: :integer},
            url: {type: :string, format: :uri},
            smallUrl: {type: :string, format: :uri},
            mediumUrl: {type: :string, format: :uri},
            largeUrl: {type: :string, format: :uri},
            xlargeUrl: {type: :string, format: :uri},
            width: {type: :integer},
            height: {type: :integer},
            uploadedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[name contentType size url uploadedAt]
        })
      end
    end
  end
end
