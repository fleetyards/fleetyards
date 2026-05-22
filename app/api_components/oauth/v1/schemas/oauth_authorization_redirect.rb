# frozen_string_literal: true

module Oauth
  module V1
    module Schemas
      class OauthAuthorizationRedirect
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            status: {type: :string, enum: %w[redirect post]},
            redirect_uri: {type: :string}
          },
          additionalProperties: false,
          required: %w[status redirect_uri]
        })
      end
    end
  end
end
