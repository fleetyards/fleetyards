# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class Oauth2
        include SchemaConcern

        schema({
          type: :oauth2,
          flows: {
            authorizationCode: {
              authorizationUrl: "https://fleetyards.net/oauth/authorize",
              tokenUrl: "https://fleetyards.net/oauth/token",
              scopes: (Doorkeeper.config.default_scopes.to_a + Doorkeeper.config.optional_scopes.to_a).map do |scope|
                [scope, I18n.t("doorkeeper.scopes.#{scope}")]
              end.to_h
            }
          }
        })
      end
    end
  end
end
