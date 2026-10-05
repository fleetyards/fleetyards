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
      option :name, "bluesky"

      option :client_options, {
        site: "https://bsky.social",
        authorize_url: "https://bsky.social/oauth/authorize",
        token_url: "https://bsky.social/oauth/token"
      }

      uid { did }

      info do
        {
          did: did,
          nickname: handle&.delete_suffix(".bsky.social"),
          pds_host: options.client_options.site
        }
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
    end
  end
end

OmniAuth.config.add_camelization("bluesky", "Bluesky")
