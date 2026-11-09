# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterFace
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "A character exported from the game's character creator, kept as the uploaded file",
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            token: {type: :string, description: "Shows the character to anyone who has it, as a share link does"},
            body: ::V1::Schemas::Enums::OutfitBodyEnum,
            dnaStamp: {type: [:string, :null], description: "The face library build the file was saved against; absent for a preset without a face"},
            genderHash: {type: [:string, :null]},
            formatVersion: {type: :integer, description: "7 has 12 face parts, 8 adds the neck"},
            gameVersion: {type: [:string, :null], description: "The live game version when the file was uploaded"},
            file: ::Shared::V1::Schemas::MediaFile,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id name token body dnaStamp genderHash formatVersion gameVersion file createdAt updatedAt]
        })
      end
    end
  end
end
