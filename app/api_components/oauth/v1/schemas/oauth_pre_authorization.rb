# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      class OauthPreAuthorization
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            clientId: {type: :string},
            clientName: {type: :string},
            redirectUri: {type: :string},
            state: {type: :string, nullable: true},
            responseType: {type: :string},
            responseMode: {type: :string, nullable: true},
            scope: {type: :string},
            codeChallenge: {type: :string, nullable: true},
            codeChallengeMethod: {type: :string, nullable: true},
            scopes: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  name: {type: :string},
                  description: {type: :string}
                },
                required: %w[name description]
              }
            }
          },
          additionalProperties: false,
          required: %w[clientId clientName redirectUri responseType scope scopes]
        })
      end
    end
  end
end
