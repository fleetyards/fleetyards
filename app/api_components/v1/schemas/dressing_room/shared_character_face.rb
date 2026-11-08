# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class SharedCharacterFace
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            token: {type: :string},
            name: {type: :string},
            body: ::V1::Schemas::Enums::OutfitBodyEnum,
            file: ::Shared::V1::Schemas::MediaFile,
            character: {
              description: "The resolved character in the export's sc-chf-character format, with every asset path replaced by its URL (null while that asset is not imported); absent until the customizer export is imported",
              anyOf: [{type: :object, additionalProperties: true}, {type: :null}]
            }
          },
          additionalProperties: false,
          required: %w[token name body file character]
        })
      end
    end
  end
end
