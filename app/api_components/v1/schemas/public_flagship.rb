# frozen_string_literal: true

module V1
  module Schemas
    class PublicFlagship
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        description: "The ship the user marked as their flagship, when it is public",
        properties: {
          name: {type: :string},
          modelName: {type: :string},
          modelSlug: {type: :string},
          manufacturerName: {type: :string},
          angledView: ::Shared::V1::Schemas::MediaFile,
          angledViewColored: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[modelName modelSlug]
      })
    end
  end
end
