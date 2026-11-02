# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class Outfit
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            items: {type: :array, items: ::V1::Schemas::DressingRoom::OutfitItem},
            heldWeapon: ::V1::Schemas::Enums::NullableOutfitWeaponSlotEnum,
            body: ::V1::Schemas::Enums::OutfitBodyEnum,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name items heldWeapon body createdAt updatedAt]
        })
      end
    end
  end
end
