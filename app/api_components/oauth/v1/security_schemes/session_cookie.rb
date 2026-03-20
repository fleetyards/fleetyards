# frozen_string_literal: true

module Oauth
  module V1
    module SecuritySchemes
      class SessionCookie
        include Rswag::SchemaComponents::Component

        schema({
          type: :apiKey,
          description: "Session Cookie",
          name: "FLTYRD",
          in: :cookie
        })
      end
    end
  end
end
