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
            animations: {
              description: "The clips that pose the body and every item rigged to it, by bone name; absent until exported",
              anyOf: [::Shared::V1::Schemas::MediaFile, {type: :null}]
            },
            clips: {type: :array, items: ::V1::Schemas::DressingRoom::CharacterBodyClip}
          },
          additionalProperties: false,
          required: %w[key holo animations clips]
        })
      end
    end
  end
end
