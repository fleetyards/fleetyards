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
            storedItems: {type: :array, items: ::V1::Schemas::DressingRoom::OutfitStoredItem},
            heldWeapon: ::V1::Schemas::Enums::NullableOutfitWeaponSlotEnum,
            body: ::V1::Schemas::Enums::OutfitBodyEnum,
            characterFace: {
              description: "The user's own character wearing the outfit",
              anyOf: [::V1::Schemas::DressingRoom::OutfitCharacterFace, {type: :null}]
            },
            default: {type: :boolean, description: "The user's default outfit: the dressing room opens on it and the character avatars are drawn from it"},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name items storedItems heldWeapon body characterFace default createdAt updatedAt]
        })
      end
    end
  end
end
