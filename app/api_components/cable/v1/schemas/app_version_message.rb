# frozen_string_literal: true

module Cable
  module V1
    module Schemas
      # Pushed on deploy, and on subscribe, so a client running older assets
      # can offer a reload. Same shape as the REST version endpoint.
      class AppVersionMessage
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            version: {type: :string},
            codename: {type: :string},
            announcement: {"$ref": "#/components/schemas/VersionAnnouncement"}
          },
          additionalProperties: false,
          required: %w[version codename]
        })
      end
    end
  end
end
