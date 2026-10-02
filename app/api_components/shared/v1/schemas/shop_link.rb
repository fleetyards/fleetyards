# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # A shop, named, for a link to its page, with the place it is at.
      class ShopLink
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            slug: {type: :string},
            location: ::Shared::V1::Schemas::LocationLink
          },
          additionalProperties: false,
          required: %w[name slug location]
        })
      end
    end
  end
end
