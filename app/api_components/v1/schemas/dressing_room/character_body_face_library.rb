# frozen_string_literal: true

module V1
  module Schemas
    module DressingRoom
      class CharacterBodyFaceLibrary
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          description: "The library a character file's head, eyes and teeth are blended from on this body",
          properties: {
            library: {type: :string, description: "The build, <body>-<DNA stamp>, e.g. male-6a268db0"},
            index: ::Shared::V1::Schemas::MediaFile,
            positions: ::Shared::V1::Schemas::MediaFile,
            normals: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[library index positions normals]
        })
      end
    end
  end
end
