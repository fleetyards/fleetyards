# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Video
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            type: {"$ref": "#/components/schemas/VideoTypeEnum"},
            url: {type: :string, format: :uri},
            videoId: {type: :string},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id url videoId type createdAt updatedAt]
        })
      end
    end
  end
end
