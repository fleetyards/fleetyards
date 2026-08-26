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
              manufacturer: {
                type: :object,
                properties: {
                  name: {type: [:string, :null]},
                  slug: {type: [:string, :null]},
                  code: {type: [:string, :null]}
                },
                additionalProperties: false,
                required: %w[name slug code]
              },
              classification: {type: [:string, :null]},
              classificationLabel: {type: [:string, :null]},
              inHangar: {type: :boolean},
              onWishlist: {type: :boolean},
              media: Shared::V1::Schemas::StoreImageMedia
            },
            additionalProperties: false,
            required: %w[id name slug manufacturer classification classificationLabel inHangar onWishlist media]
          })
        end
      end
    end
  end
end
