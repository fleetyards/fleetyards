# frozen_string_literal: true

module V1
  module Schemas
    class OauthApplication
      include Rswag::SchemaComponents::Component

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          uid: {type: :string},
          confidential: {type: :boolean},
          redirectUri: {type: :string},
          scopes: {type: :string},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name uid confidential redirectUri scopes createdAt updatedAt]
      })
    end
  end
end
