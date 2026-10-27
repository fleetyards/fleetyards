# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class RafflePrize
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            storeImage: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
