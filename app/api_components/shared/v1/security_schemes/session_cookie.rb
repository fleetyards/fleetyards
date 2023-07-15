# frozen_string_literal: true

module Shared
  module V1
    module SecuritySchemes
      class SessionCookie
        include SchemaConcern

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
