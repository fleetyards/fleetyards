# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Shop
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string},
            itemsCount: {type: :integer},
            image: ::Shared::V1::Schemas::MediaFile,
            location: ::Shared::V1::Schemas::LocationLink,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name slug itemsCount location createdAt updatedAt]
        })
      end
    end
  end
end
