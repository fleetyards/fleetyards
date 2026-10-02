# frozen_string_literal: true

module V1
  module Schemas
    # A shop as its place lists it: what it is and how much it carries.
    class LocationShop
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          itemsCount: {type: :integer},
          counts: {type: :array, items: ::V1::Schemas::ShopItemCount},
          image: ::Shared::V1::Schemas::MediaFile
        },
        additionalProperties: false,
        required: %w[id name slug itemsCount counts]
      })
    end
  end
end
