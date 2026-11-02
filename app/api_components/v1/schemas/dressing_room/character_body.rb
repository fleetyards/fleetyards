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
            holo: ::Shared::V1::Schemas::MediaFile
          },
          additionalProperties: false,
          required: %w[key holo]
        })
      end
    end
  end
end
