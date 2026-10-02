# frozen_string_literal: true

module V1
  module Schemas
    # A shop UEX lists at a place, and everything it sells or rents there.
    class Shop
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          image: ::Shared::V1::Schemas::MediaFile,
          location: ::Shared::V1::Schemas::LocationLink,
          # The place and every place above it, outermost first, for the
          # breadcrumbs. The star is left out, as on a place's own page.
          ancestors: {type: :array, items: ::Shared::V1::Schemas::LocationLink},
          system: {anyOf: [::Shared::V1::Schemas::LocationLink, {type: :null}]},
          itemsCount: {type: :integer},
          counts: {type: :array, items: ::V1::Schemas::ShopItemCount},
          items: {type: :array, items: ::V1::Schemas::ShopItem},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name slug location ancestors system itemsCount counts items createdAt updatedAt]
      })
    end
  end
end
