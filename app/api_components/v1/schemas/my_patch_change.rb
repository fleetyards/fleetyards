# frozen_string_literal: true

module V1
  module Schemas
    class MyPatchChange
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          model: {
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string},
              slug: {type: :string},
              manufacturerName: {type: :string},
              storeImage: ::Shared::V1::Schemas::MediaFile
            },
            additionalProperties: false,
            required: %w[id name slug]
          },
          ownedCount: {type: :integer},
          wanted: {type: :boolean},
          changeCount: {type: :integer},
          changes: {type: :array, items: ::V1::Schemas::Models::Changes::ModelBuildChange}
        },
        additionalProperties: false,
        required: %w[model ownedCount wanted changeCount changes]
      })
    end
  end
end
