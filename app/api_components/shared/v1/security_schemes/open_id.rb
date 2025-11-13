# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class OpenId
        include Rswag::SchemaComponents::Component

        schema({
          type: :openIdConnect,
          openIdConnectUrl: "http://fleetyards.test/.well-known/openid-configuration"
        })
      end
    end
  end
end
