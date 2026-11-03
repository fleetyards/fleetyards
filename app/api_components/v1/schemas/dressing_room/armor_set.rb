# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class ArmorSet
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            manufacturerName: {type: [:string, :null]},
            itemType: {type: [:string, :null]},
            itemTypeLabel: {type: [:string, :null]},
            image: {
              description: "A picture of one of the set's pieces: the core's render where it has one, another piece's render, then a store image; absent when none has a picture",
              anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]
            },
            pieces: {type: :array, items: ::V1::Schemas::DressingRoom::ArmorSetPiece}
          },
          additionalProperties: false,
          required: %w[name manufacturerName itemType itemTypeLabel image pieces]
        })
      end
    end
  end
end
