# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class PublicCharacter
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The user's default outfit, enough to open it in the dressing room",
          properties: {
            body: ::V1::Schemas::Enums::OutfitBodyEnum,
            heldWeapon: ::V1::Schemas::Enums::NullableOutfitWeaponSlotEnum,
            characterToken: {type: [:string, :null], description: "Only when the user shows their own character; otherwise the outfit is worn by the game's default face"},
            items: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  slot: ::V1::Schemas::Enums::OutfitSlotEnum,
                  slug: {type: :string}
                },
                additionalProperties: false,
                required: %w[slot slug]
              }
            },
            storedItems: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  holder: ::V1::Schemas::Enums::OutfitHolderEnum,
                  slug: {type: :string},
                  quantity: {type: :integer}
                },
                additionalProperties: false,
                required: %w[holder slug quantity]
              }
            }
          },
          additionalProperties: false,
          required: %w[body heldWeapon characterToken items storedItems]
        })
      end
    end
  end
end
