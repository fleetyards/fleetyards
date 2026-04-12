# frozen_string_literal: true

module Oauth
  class ClientMetadataController < ActionController::API
    def show
      jwk_json = Rails.application.credentials.dig(:bluesky, :jwk)

      return head(:not_found) if jwk_json.blank?

      jwk = JSON.parse(jwk_json)
      client_id = Rails.configuration.app.bluesky[:client_id]
      base_url = AppEndpointResolver.new.frontend_endpoint

      render json: {
        client_id: client_id,
        application_type: "web",
        client_name: Rails.configuration.app.name,
        client_uri: base_url,
        dpop_bound_access_tokens: true,
        grant_types: ["authorization_code", "refresh_token"],
        redirect_uris: ["#{base_url}/users/auth/bluesky/callback"],
        response_types: ["code"],
        scope: "atproto transition:generic",
        token_endpoint_auth_method: "private_key_jwt",
        token_endpoint_auth_signing_alg: "ES256",
        jwks: {
          keys: [jwk]
        }
      }
    end
  end
end
