# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # Patreon's OAuth2, written here rather than taken from a gem: the only one
    # published (omniauth-patreon 1.0.2) was last released in 2018, predating
    # both OmniAuth 2 and Patreon's v2 API. The flow itself is unremarkable
    # OAuth2, so it rides omniauth-oauth2 like every provider gem this app uses.
    class Patreon < OmniAuth::Strategies::OAuth2
      IDENTITY_PATH = "/api/oauth2/v2/identity"
      USER_FIELDS = %w[full_name vanity image_url email].join(",")

      option :name, "patreon"

      option :client_options, {
        site: "https://www.patreon.com",
        authorize_url: "https://www.patreon.com/oauth2/authorize",
        token_url: "https://www.patreon.com/api/oauth2/token",
        # oauth2 2.x defaults to :basic_auth. Patreon wants the client
        # credentials as form parameters and refuses the exchange without
        # them, which fails the callback before raw_info is ever reached.
        auth_scheme: :request_body
      }

      option :token_params, {parse: :json}

      # `identity` is what names the account; the bracketed one adds its email.
      # Both are v2 scopes and a v2 client's own token carries them.
      option :scope, "identity identity[email]"

      # The Patreon account's own id -- the same value that appears as a
      # member's user relationship in the campaign feed, which is what makes a
      # contribution matchable to this account.
      uid { raw_info.dig("data", "id") }

      info do
        attrs = raw_info.dig("data", "attributes") || {}

        {
          name: attrs["full_name"],
          nickname: attrs["vanity"],
          email: attrs["email"],
          image: attrs["image_url"]
        }
      end

      extra do
        {raw_info: raw_info}
      end

      def raw_info
        @raw_info ||= access_token.get(
          "#{IDENTITY_PATH}?fields%5Buser%5D=#{USER_FIELDS}"
        ).parsed || {}
      end

      # OAuth2 4.x insists on an explicit redirect_uri at both legs, and it must
      # be byte-identical to the one registered on the client.
      def callback_url
        full_host + callback_path
      end
    end
  end
end

OmniAuth.config.add_camelization("patreon", "Patreon")
