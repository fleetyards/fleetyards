# frozen_string_literal: true

module V1
  module Schemas
    class ScDataBuild
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          environment: {type: :string},
          version: {type: :string},
          default: {type: :boolean},
          loadingScreens: {type: :array, items: ::Shared::V1::Schemas::MediaFile}
        },
        additionalProperties: false,
        required: %w[environment version default loadingScreens]
      })
    end
  end
end
