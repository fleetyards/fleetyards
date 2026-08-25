# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Pushed on deploy so a client running older assets can offer a reload.
      # No REST counterpart: the version is embedded in the page on load.
      class AppVersionMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            version: {type: :string},
            codename: {type: :string}
          },
          additionalProperties: false,
          required: %w[version codename]
        })
      end
    end
  end
end
