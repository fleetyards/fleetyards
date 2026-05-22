# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      module Inputs
        class OauthAuthorizationInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              clientId: {type: :string},
              redirectUri: {type: :string},
              responseType: {type: :string},
              responseMode: {type: :string, nullable: true},
              scope: {type: :string},
              state: {type: :string, nullable: true},
              codeChallenge: {type: :string, nullable: true},
              codeChallengeMethod: {type: :string, nullable: true}
            },
            additionalProperties: false,
            required: %w[clientId redirectUri responseType scope]
          })
        end
      end
    end
  end
end
