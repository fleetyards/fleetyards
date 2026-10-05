# frozen_string_literal: true

require "omniauth/strategies/atproto"

module OmniAuth
  module Strategies
    # omniauth-atproto finds a user's authorization server from a handle posted
    # with the request, and the sign-in buttons post none -- without it the
    # strategy redirects to an authorize URL it never set. Every account we
    # expect lives on bsky.social, so its server is fixed here instead.
    #
    # The gem also names no uid and no nickname, and the callback needs both:
    # the connection's uid is NOT NULL, and a new user is created under the
    # nickname.
    class Bluesky < OmniAuth::Strategies::Atproto
      CLIENT_ASSERTION_TYPE = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

      option :name, "bluesky"

      option :client_options, {
        site: "https://bsky.social",
        authorize_url: "https://bsky.social/oauth/authorize",
        token_url: "https://bsky.social/oauth/token"
      }

      option :par_url, "https://bsky.social/oauth/par"

      uid { did }

      info do
        {
          did: did,
          nickname: handle&.delete_suffix(".bsky.social"),
          pds_host: options.client_options.site
        }
      end

      # bsky.social requires pushed authorization requests, which the gem does
      # not make: the parameters are posted to the server first, and the
      # browser is sent on with only the reference it hands back. The DPoP
      # proof is signed with the client key, as the gem's token exchange does --
      # the server binds the code to the key that pushed the request.
      def request_phase
        params = {
          client_id: options.client_id,
          response_type: "code",
          redirect_uri: callback_url,
          client_assertion_type: CLIENT_ASSERTION_TYPE,
          client_assertion: client_assertion
        }.merge(authorize_params.to_hash(symbolize_keys: true))

        response = AtProto::Client.new(private_key: options.private_key).dpop_handler.make_request(
          options.par_url,
          :post,
          headers: {"Content-Type" => "application/x-www-form-urlencoded"},
          body: URI.encode_www_form(params)
        )

        redirect "#{options.client_options.authorize_url}?#{URI.encode_www_form(
          client_id: options.client_id,
          request_uri: response.fetch("request_uri")
        )}"
      rescue AtProto::Error, KeyError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
        fail!(:pushed_authorization_request_failed, e)
      end

      def did
        access_token.params["sub"]
      end

      # The token names only the DID; the handle comes from its DID document,
      # and only once it resolves back to that DID.
      def handle
        return @handle if defined?(@handle)

        @handle = begin
          DIDKit::Resolver.new.get_verified_handle(did)
        rescue => e
          Rails.logger.warn("Bluesky handle lookup failed for #{did}: #{e.message}")
          nil
        end
      end

      private def client_assertion
        now = Time.now.to_i

        JWT.encode(
          {
            iss: options.client_id,
            sub: options.client_id,
            aud: options.client_options.site,
            jti: SecureRandom.uuid,
            iat: now,
            exp: now + 300
          },
          options.private_key,
          "ES256",
          {typ: "jwt", kid: options.client_jwk[:kid]}
        )
      end
    end
  end
end

OmniAuth.config.add_camelization("bluesky", "Bluesky")
