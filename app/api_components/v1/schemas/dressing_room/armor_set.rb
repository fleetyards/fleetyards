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
            manufacturerName: {type: :string, nullable: true},
            itemType: {type: :string, nullable: true},
            itemTypeLabel: {type: :string, nullable: true},
            pieces: {type: :array, items: ::V1::Schemas::DressingRoom::ArmorSetPiece}
          },
          additionalProperties: false,
          required: %w[name manufacturerName itemType itemTypeLabel pieces]
        })
      end
    end
  end
end
