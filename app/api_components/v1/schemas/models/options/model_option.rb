# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Options
        class ModelOption
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              media: {
                type: :object,
                properties: {
                  storeImage: {"$ref": "#/components/schemas/MediaFile"}
                },
                additionalProperties: false
              }
            },
            additionalProperties: false,
            required: %w[id name slug media]
          })
        end
      end
    end
  end
end
