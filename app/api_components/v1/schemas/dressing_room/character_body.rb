# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBody
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            key: {type: :string, description: "The body's folder in the export, e.g. male"},
            holo: ::Shared::V1::Schemas::MediaFile,
            holoTextured: {
              description: "The body with the game's skin, eye, teeth and underwear textures; absent until exported",
              anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]
            },
            animations: {
              description: "The clips that pose the body and every item rigged to it, by bone name; absent until exported",
              anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]
            },
            weaponInHand: {
              description: "The hand bones a weapon is held by, and the fixed turn its holo needs there; absent until exported",
              anyOf: [::V1::Schemas::DressingRoom::CharacterBodyWeaponInHand, {type: :null}]
            },
            lighting: {
              type: :array,
              description: "The game customizer's review lights for a whole outfit, from the character's feet in glTF axes; empty until exported",
              items: ::V1::Schemas::DressingRoom::CharacterBodyLight
            },
            clips: {type: :array, items: ::V1::Schemas::DressingRoom::CharacterBodyClip}
          },
          additionalProperties: false,
          required: %w[key holo holoTextured animations weaponInHand lighting clips]
        })
      end
    end
  end
end
