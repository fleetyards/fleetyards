# frozen_string_literal: true

module V1
  module Schemas
    class Commodity
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          slug: {type: :string},
          commodityType: {type: [:string, :null]},
          description: {type: [:string, :null]},
          storeImage: ::Shared::V1::Schemas::MediaFile,

          # The UEX snapshot prices commodities at every terminal that trades
          # them, which is the whole point of syncing it -- the same shape the
          # component and equipment payloads carry.
          availability: Shared::V1::Schemas::ItemAvailability,

          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name slug availability createdAt updatedAt]
      })
    end
  end
end
