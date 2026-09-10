# frozen_string_literal: true

module V1
  module Schemas
    class OauthApplication
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          uid: {type: :string},
          confidential: {type: :boolean},
          redirectUri: {type: :string},
          scopes: {type: :string},
          state: {type: :string, enum: %w[pending approved rejected]},
          rejectionReason: {type: [:string, :null]},
          logo: ::Shared::V1::Schemas::MediaFile,
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name uid confidential redirectUri scopes state createdAt updatedAt]
      })
    end
  end
end
