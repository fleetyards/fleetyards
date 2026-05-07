# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class OpenId
        include OpenapiRuby::Components::Base

        component_type :securitySchemes

        schema({
          type: :openIdConnect,
          openIdConnectUrl: "https://fleetyards.net/.well-known/openid-configuration"
        })
      end
    end
  end
end
